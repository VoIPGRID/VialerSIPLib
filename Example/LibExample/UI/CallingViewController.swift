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
        case disabled
    }

    // MARK: - UI
    @IBOutlet weak var makeCallButton   : UIButton!
    @IBOutlet weak var hangUpButton     : UIButton!
    @IBOutlet weak var phoneNumberField : UITextField! { didSet{configure(phoneNumberField: phoneNumberField)} }

    private var currentCall: Call?
    private var state      : CallState = .idle { didSet{ stateChanged()} }

    override func viewDidLoad() {
        super.viewDidLoad()
        responseHandler?.handle(msg: .feature(.flag(.useCase(.isEnbaled(.startCall)))))
        state = .idle
    }

    // MARK: - Call Making
    @IBAction 
    func makeCall(_ sender: Any) {
        responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.start(phoneNumberField.text ?? "")))))))
    }
    
    @IBAction
    func endCall(_ sender: Any) {
        if let c = currentCall { responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.stop(c))))))) }
    }

    // MARK: - Incomming Messages
    override func handle(msg: Message) {
        super.handle(msg: msg)
        
        func update(call: Call?, newState: CallState) { currentCall = call; state = newState }
        
        if case .feature(.calling(.useCase(.call(.action( .callDidStop(let call)))))) = msg { update(call: call, newState:    .idle) }
        if case .feature(.calling(.useCase(.call(.action(     .dialing(let call)))))) = msg { update(call: call, newState: .dialing) }
        if case .feature(.calling(.useCase(.call(.action(.callDidStart(let call)))))) = msg { update(call: call, newState: .calling) }
        if case .feature(.calling(.useCase(.call(.action(  .callFailed(let call)))))) = msg { update(call: call, newState:  .failed) }
        if case .feature(   .flag(.useCase(.didDisable(.startCall))))                 = msg { update(call: nil, newState: .disabled) }
    }

    // MARK: - State Handling
    
    private var resetTimer: Timer?
    private func stateChanged() {
        func updateUI(enabledMakeCallButton: Bool, enableHangUpButton:Bool, numberFieldColor: UIColor, resetToIdle: Bool) {
            if true == resetTimer?.isValid {
                resetTimer?.invalidate()
                resetTimer = nil
            }
            phoneNumberField.layer.borderColor = numberFieldColor.cgColor
                        hangUpButton.isEnabled = enableHangUpButton
                      makeCallButton.isEnabled = enabledMakeCallButton
            if resetToIdle {
                resetTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false){ [weak self] _ in self?.state = .idle }
            }
        }

        func disableCalling() {
            makeCallButton.isHidden = true
            hangUpButton.isHidden = true
        }
        switch state {
        case .idle   : updateUI(enabledMakeCallButton:  true, enableHangUpButton: false, numberFieldColor: .white, resetToIdle: false)
        case .dialing: updateUI(enabledMakeCallButton:  true, enableHangUpButton:  true, numberFieldColor:  .cyan, resetToIdle: false)
        case .calling: updateUI(enabledMakeCallButton: false, enableHangUpButton:  true, numberFieldColor: .green, resetToIdle: false)
        case .failed : updateUI(enabledMakeCallButton:  true, enableHangUpButton: false, numberFieldColor:   .red, resetToIdle:  true)
        case .disabled: disableCalling()
        }
    }
}

// MARK: - Configure Functions
private func configure(phoneNumberField field: UITextField) {
    field.layer.borderColor  = UIColor.clear.cgColor
    field.layer.borderWidth  = 3
    field.layer.cornerRadius = 5
}
