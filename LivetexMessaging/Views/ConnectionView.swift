//
//  ConnectionView.swift
//  LivetexMessaging
//
//  Created by Nikita Fomichev on 29.04.2022.
//  Copyright © 2022 Livetex. All rights reserved.
//

import UIKit

final class ConnectionView: UIView {

    private struct Appearance {
        static let titleLabelFont: UIFont = .systemFont(ofSize: 17, weight: .semibold)
    }

    // MARK: - Views

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        return activityIndicator
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Appearance.titleLabelFont
        label.textAlignment = .left
        label.textColor = .black
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(activityIndicator)

        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.frame.size = CGSize(width: bounds.width,
                                       height: bounds.height)

        activityIndicator.frame = CGRect(x: 0,
                                         y: 0,
                                         width: bounds.height,
                                         height: bounds.height)
    }

}

extension ConnectionView {

    func startActivityIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }

    func stopActivityIndicator() {
        activityIndicator.stopAnimating()
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}

extension ConnectionView {

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: activityIndicator.rightAnchor, constant: 8)
        ])
    }
}
