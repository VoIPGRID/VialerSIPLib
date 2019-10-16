//
//  CallingViewController.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

final
class CallingViewController: MessageViewController {
    
    enum CallState {
        case idle
        case calling
        case failed
    }
    
    @IBOutlet weak var makeCall: UIButton!
    @IBOutlet weak var hangUp: UIButton!
    @IBOutlet weak var phoneNumberField: UITextField!
    
    private var currentCall: Call?
    private var state: CallState = .idle { didSet{ stateChanged()} }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        state = .idle
    }
    
    @IBAction func endCall(_ sender: Any) {
        guard let currentCall = currentCall else { return }
        responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.stop(currentCall)))))))
    }
    
    @IBAction func call(_ sender: Any) {
        responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.start(phoneNumberField.text ?? "")))))))
    }
    
    override func handle(msg: Message) {
        super.handle(msg: msg)
        
        if case .feature(.calling(.useCase(.call(.action(.callDidStart(let call)))))) = msg {
            currentCall = call
            state = .calling
        }
        
        if case .feature(.calling(.useCase(.call(.action(.failedToStartCall(let call)))))) = msg {
            currentCall = call
            state = .failed
        }

        if case .feature(.calling(.useCase(.call(.action(.callDidStop(let call)))))) = msg {
            currentCall = call
            state = .idle
        }
    }
    
    private func stateChanged() {
        func updateUI(hangUpEnable:Bool, makeCallEnabled: Bool, numberFiledColor: UIColor) {
            phoneNumberField.backgroundColor = numberFiledColor
            hangUp.isEnabled = hangUpEnable
            makeCall.isEnabled = makeCallEnabled
        }
        
        switch state {
        case .idle:
            updateUI(
                    hangUpEnable: false,
                 makeCallEnabled: true,
                numberFiledColor: .white
            )
        case .calling:
            updateUI(
                    hangUpEnable: true,
                 makeCallEnabled: false,
                numberFiledColor: .green
            )
        case .failed:
            updateUI(
                    hangUpEnable: false,
                 makeCallEnabled: true,
                numberFiledColor: .orange
            )
        }
    }
}
