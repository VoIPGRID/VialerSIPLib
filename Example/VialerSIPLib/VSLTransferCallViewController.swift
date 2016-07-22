//
//  VSLTransferCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

@objc class VSLTransferCallViewController: VSLMakeCallViewController {

    // MARK: - Configuration

    private struct Configuration {
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

    private var newCall: VSLCall?

    // MARK - Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.currentDevice().proximityMonitoringEnabled = false
        updateUI()
        currentCall?.addObserver(self, forKeyPath: "callState", options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        currentCall?.removeObserver(self, forKeyPath: "callState")
    }

    // MARK: - Outlets

    @IBOutlet weak var currentCallNumberLabel: UILabel!
    @IBOutlet weak var currentCallStatusLabel: UILabel!

    // MARK: - Actions

    @IBAction func cancelTransferButtonPressed(sender: UIBarButtonItem) {
        if let call = currentCall where call.callState != .Disconnected {
            performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCallInProgress, sender: nil)
        } else {
            performSegueWithIdentifier(Configuration.Segues.UnwindToMainView, sender: nil)
        }
    }

    @IBAction override func callButtonPressed(sender: UIButton) {
        UIDevice.currentDevice().proximityMonitoringEnabled = true
        if let number = numberToDialLabel.text where number != "" {
            currentCall?.account.callNumber(number) { (error, call) in
                self.newCall = call
                self.performSegueWithIdentifier(Configuration.Segues.SecondCallActive, sender: nil)
            }
        }
    }

    override func updateUI() {
        super.updateUI()
        guard let call = currentCall else { return }
        currentCallNumberLabel?.text = call.callerNumber!
        if call.callState == .Disconnected {
            currentCallStatusLabel?.text = "Disconnected"
        } else {
            currentCallStatusLabel?.text = "ON HOLD"
        }
    }

    // MARK: - Segues

    @IBAction func unwindToSetupSecondCallSegue(segue: UIStoryboardSegue) {}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let secondCallVC = segue.destinationViewController as? VSLSecondCallViewController {
            secondCallVC.firstCall = currentCall
            secondCallVC.activeCall = newCall
        } else if let callVC = segue.destinationViewController as? VSLCallViewController {
            if let call = newCall where call.callState != .Null && call.callState != .Disconnected {
                callVC.activeCall = call
            } else if let call = currentCall where call.callState != .Null && call.callState != .Disconnected {
                callVC.activeCall = call
            }
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext && keyPath == "callState" {
            dispatch_async(GlobalMainQueue) {
                self.updateUI()
                if let call = self.currentCall where call.callState == .Disconnected {
                    if let newCall = self.newCall where newCall.callState != .Null {
                        self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCallInProgress, sender: nil)
                    } else {
                        self.performSegueWithIdentifier(Configuration.Segues.UnwindToMainView, sender: nil)
                    }
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}