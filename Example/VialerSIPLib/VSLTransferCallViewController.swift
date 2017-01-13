//
//  VSLTransferCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

@objc class VSLTransferCallViewController: VSLMakeCallViewController {

    // MARK: - Configuration

    fileprivate struct Configuration {
        struct Segues {
            static let SecondCallActive = "SecondCallActiveSegue"
            static let UnwindToMainView = "UnwindToMainViewSegue"
            static let ShowKeypad = "ShowKeypadSegue"
            static let UnwindToFirstCallInProgress = "UnwindToFirstCallInProgressSegue"
        }
    }

    // MARK: - Properties

    var currentCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    fileprivate var newCall: VSLCall?

    // MARK - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        currentCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentCall?.removeObserver(self, forKeyPath: "callState")
    }

    // MARK: - Outlets

    @IBOutlet weak var currentCallNumberLabel: UILabel!
    @IBOutlet weak var currentCallStatusLabel: UILabel!

    // MARK: - Actions

    @IBAction func cancelTransferButtonPressed(_ sender: UIBarButtonItem) {
        if let call = currentCall, call.callState != .disconnected {
            performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCallInProgress, sender: nil)
        } else {
            performSegue(withIdentifier: Configuration.Segues.UnwindToMainView, sender: nil)
        }
    }

    @IBAction override func callButtonPressed(_ sender: UIButton) {
        guard let number = numberToDialLabel.text, number != "" else { return }

        callManager.startCall(toNumber: number, for: currentCall!.account! ) { (call, error) in
            if error != nil {
                DDLogWrapper.logError("Could not start second call: \(error)")
            } else {
                self.newCall = call
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: Configuration.Segues.SecondCallActive, sender: nil)
                }
            }
        }
    }

    override func updateUI() {
        super.updateUI()
        guard let call = currentCall else { return }
        currentCallNumberLabel?.text = call.callerNumber!
        if call.callState == .disconnected {
            currentCallStatusLabel?.text = "Disconnected"
        } else {
            currentCallStatusLabel?.text = "ON HOLD"
        }
    }

    // MARK: - Segues

    @IBAction func unwindToSetupSecondCallSegue(_ segue: UIStoryboardSegue) {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let secondCallVC = segue.destination as? VSLSecondCallViewController {
            secondCallVC.firstCall = currentCall
            secondCallVC.activeCall = newCall
        } else if let callVC = segue.destination as? VSLCallViewController {
            if let call = newCall, call.callState != .null && call.callState != .disconnected {
                callVC.activeCall = call
            } else if let call = currentCall, call.callState != .null && call.callState != .disconnected {
                callVC.activeCall = call
            }
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext && keyPath == "callState" {
            DispatchQueue.main.async {
                self.updateUI()
                if let call = self.currentCall, call.callState == .disconnected {
                    if let newCall = self.newCall, newCall.callState != .null {
                        self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCallInProgress, sender: nil)
                    } else {
                        self.performSegue(withIdentifier: Configuration.Segues.UnwindToMainView, sender: nil)
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
