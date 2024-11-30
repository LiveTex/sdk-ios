# sdk-ios
# LivetexCore
iOS SDK

# Установка
A description of this package.
Откройте Ваш проект в XCode, затем щелкните на вашем проекте в навигаторе правлй кнопкой мыши, выберите `Add packages...`, в появившемся окне в строке поиска вставьте адрес https://github.com/LiveTex/sdk-ios и установите SPM пакет.
# Настройка
Для инициализации чата и SDK в коде приложения для iOS потребуется указать идентификатор точки контакта.
Для этого добавьте запись в Info.plist как показано ниже:
```
<key>Livetex</key>
<dict>
    <key>LivetexAppID</key>
    <string>touchPoint</string>
</dict>
```
# Использование
## Установка кастомного эндпоинта для подключения
```
let loginService = LivetexAuthService(token: "visitorToken", deviceToken: "apns deviceToken", authPath: "your authentication url")
```
## Авторизация и установление соединения с сервером
```
let loginService = LivetexAuthService(token: "visitorToken", deviceToken: "apns deviceToken")
loginService.requestAuthorization { [weak self] result in
    DispatchQueue.main.async {
        switch result {
        case let .success(token):
            let sessionService = LivetexSessionService(token: token)
            sessionService.connect()
        case let .failure(error):
            print(error.localizedDescription)
        }
    }
}
```
## Отправка событий
```
let event = ClientEvent(.text("Hello world"))
sessionService.sendEvent(event)
```
## Получение событий
```
sessionService.onEvent = { [weak self] event in
    switch event {
        case let .state(result):
            doSomething()
        case .attributes:
            doSomething()
    }
}
```
