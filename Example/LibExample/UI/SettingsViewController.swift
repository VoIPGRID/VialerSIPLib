//
//  SettingsViewController.swift
//  LibExample
//
//  Created by Manuel on 01/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

final class SettingsViewController: MessageViewController {

    @IBOutlet weak var accountNumberTextField: UITextField!
    @IBOutlet weak var modePicker: UIPickerView!

    private var         modes: [TransportMode] = TransportMode.allCases
    private var  selectedMode: TransportMode?   { didSet { configureModePicker() } }
    private var accountNumber: String = ""      { didSet { configureAccountNumber() } }

    override func viewDidLoad() {
        super.viewDidLoad()
        modePicker.delegate = self
        modePicker.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureAccountNumber()
        configureModePicker()
    }

    override func handle(msg: Message) {
        super.handle(msg: msg)
        if case .feature(.settings(.useCase(.transport(.action(.didActivate(let mode)))))) = msg { select(  mode:  mode ) }
        if case .feature(   .state(.useCase(            .persistingFailed(_, let error)))) = msg {   show( error: error ) }
        if case .feature(   .state(.useCase(                    .stateLoaded(let state)))) = msg { loaded( state: state ) }
    }
    
    private func show(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func loaded(state: AppState) {
        selectedMode = state.transportMode
        accountNumber = state.accountNumber
    }
    
    private func select(mode: TransportMode) {
        selectedMode = mode
    }
}

extension SettingsViewController {
    
    private func configureAccountNumber() {
        accountNumberTextField?.text = accountNumber
    }
    
    private func configureModePicker() {
        if
            let selectedMode = self.selectedMode,
            let idx = modes.firstIndex(where: { $0 == selectedMode })
        {
            modePicker?.selectRow(idx, inComponent: 0, animated: false)
        }
    }
}

extension SettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        responseHandler?.handle(msg: .feature(.settings(.useCase(.transport(.action(.activate(modes[row])))))))
    }
}

extension SettingsViewController: UIPickerViewDataSource  {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return modes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(modes[row])".uppercased()
    }
}
