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
    
    // MARK: - View State
    private enum CallState {
        case idle
        case dialing
        case calling
        case failed
    }
   
    // MARK: - UI
    @IBOutlet weak var makeCallButton   : UIButton!
    @IBOutlet weak var hangUpButton     : UIButton!
    @IBOutlet weak var phoneNumberField : UITextField! {didSet{configure(phoneNumberField: phoneNumberField)}}
    
    private var currentCall: Call?
    private var state      : CallState = .idle { didSet{ stateChanged()} }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = .idle
    }

    //MARK: - Call Making
    @IBAction func endCall(_ sender: Any) {
        if let c = currentCall { responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.stop(c))))))) }
    }
    
    @IBAction func makeCall(_ sender: Any) {
        responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.start(phoneNumberField.text ?? "")))))))
    }
    
    // MARK: - Incomming Messages
    override func handle(msg: Message) {
        super.handle(msg: msg)
        if case .feature(.calling(.useCase(.call(.action(.callDidStop (let call)))))) = msg { update(call: call, newState:    .idle) }
        if case .feature(.calling(.useCase(.call(.action(.dialing     (let call)))))) = msg { update(call: call, newState: .dialing) }
        if case .feature(.calling(.useCase(.call(.action(.callDidStart(let call)))))) = msg { update(call: call, newState: .calling) }
        if case .feature(.calling(.useCase(.call(.action(.callFailed  (let call)))))) = msg { update(call: call, newState:  .failed) }
    }
    
    //MARK: - State Handling
    private func update(call: Call?, newState: CallState) { currentCall = call; state = newState }
    
    private func stateChanged() {
        func updateUI(enableHangUpButton:Bool, enabledMakeCallButton: Bool, numberFieldColor: UIColor) {
            phoneNumberField.layer.borderColor = numberFieldColor.cgColor
            hangUpButton    .isEnabled         = enableHangUpButton
            makeCallButton  .isEnabled         = enabledMakeCallButton
        }
        
        switch state {
        case .idle   : updateUI(enableHangUpButton: false, enabledMakeCallButton: true,  numberFieldColor: .white)
        case .dialing: updateUI(enableHangUpButton: true,  enabledMakeCallButton: true,  numberFieldColor:  .cyan)
        case .calling: updateUI(enableHangUpButton: true,  enabledMakeCallButton: false, numberFieldColor: .green)
        case .failed : updateUI(enableHangUpButton: false, enabledMakeCallButton: true,  numberFieldColor:   .red)
        }
    }
}

//MARK: - Configure Functions
private func configure(phoneNumberField field: UITextField) {
    field.layer.borderColor  = UIColor.clear.cgColor
    field.layer.borderWidth  = 3
    field.layer.cornerRadius = 5
}
