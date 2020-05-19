//
//  DepartmentsPickerView.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

protocol DepartmentsPickerViewDelegate: AnyObject {

    func pickerView(_ pickerView: DepartmentsPickerView, didSelect item: Department)

}

class DepartmentsPickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

    var departments: [Department] = []

    weak var delegate: DepartmentsPickerViewDelegate?

    private let toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done,
                                   target: self,
                                   action: #selector(onDoneTapped))
        toolbar.setItems([flexibleSpace, done], animated: false)
        return toolbar
    }()

    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(pickerView)
        addSubview(toolbar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        toolbar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: toolbar.intrinsicContentSize.height)
        pickerView.frame = CGRect(x: 0, y: toolbar.frame.maxY, width: bounds.width, height: bounds.height)
    }

    // MARK: - Action

    @objc private func onDoneTapped() {
        delegate?.pickerView(self, didSelect: departments[pickerView.selectedRow(inComponent: 0)])
    }

    // MARK: - UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return departments.count
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return departments[row].name
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 32
    }

}
