import Foundation

protocol LivetexWebSocketConnection: AnyObject {
    var delegate: WebSocketDelegate? { get set }
    var eventQueue: DispatchQueue? { get set }
    var isOpen: Bool { get }
    func openConnection()
    func closeConnection()
    func sendText(_ text: String)
    func sendPing()
}

extension WebSocket: LivetexWebSocketConnection {
    var isOpen: Bool {
        return readyState == .open
    }

    func openConnection() {
        open()
    }

    func closeConnection() {
        close()
    }

    func sendText(_ text: String) {
        send(text: text)
    }

    func sendPing() {
        ping()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class LivetexURLSessionWebSocket: NSObject, LivetexWebSocketConnection {

    var delegate: WebSocketDelegate?
    var eventQueue: DispatchQueue?
    private(set) var isOpen = false

    private let url: URL
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var didReportClose = false

    init(url string: String) {
        self.url = URL(string: string)!
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    deinit {
        session?.invalidateAndCancel()
    }

    func openConnection() {
        guard let session = session else { return }
        var request = URLRequest(url: url)
        if let scheme = url.scheme, let host = url.host {
            request.setValue("\(scheme)://\(host)", forHTTPHeaderField: "Origin")
        }
        let task = session.webSocketTask(with: request)
        self.task = task
        task.resume()
        receive()
    }

    func closeConnection() {
        isOpen = false
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        session?.invalidateAndCancel()
    }

    func sendText(_ text: String) {
        task?.send(.string(text)) { [weak self] error in
            self?.reportError(error)
        }
    }

    func sendPing() {
        task?.sendPing { [weak self] error in
            self?.reportError(error)
        }
    }

    private func receive() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.report { delegate in
                        delegate.webSocketMessageText?(text)
                    }
                case .data(let data):
                    self.report { delegate in
                        delegate.webSocketMessageData?(data)
                    }
                @unknown default:
                    break
                }
                self.receive()
            case .failure(let error):
                self.isOpen = false
                self.task = nil
                self.session?.invalidateAndCancel()
                self.report { $0.webSocketError(error as NSError) }
                // Старый транспорт на ошибке тоже сообщает о закрытии — сохраняем это поведение.
                self.reportClose(code: URLSessionWebSocketTask.CloseCode.abnormalClosure.rawValue,
                                 reason: error.localizedDescription,
                                 wasClean: false)
            }
        }
    }

    private func report(_ action: @escaping (WebSocketDelegate) -> Void) {
        guard let delegate = delegate else { return }
        let queue = eventQueue ?? .main
        queue.async { action(delegate) }
    }

    private func reportError(_ error: Error?) {
        guard let error = error else { return }
        report { $0.webSocketError(error as NSError) }
    }

    private func reportClose(code: Int, reason: String, wasClean: Bool) {
        guard !didReportClose else { return }
        didReportClose = true
        report { $0.webSocketClose(code, reason: reason, wasClean: wasClean) }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension LivetexURLSessionWebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        LivetexTrust.handle(challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol `protocol`: String?) {
        isOpen = true
        report { $0.webSocketOpen() }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        isOpen = false
        task = nil
        self.session?.invalidateAndCancel()
        let text = reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        reportClose(code: closeCode.rawValue, reason: text, wasClean: closeCode == .normalClosure)
    }
}
