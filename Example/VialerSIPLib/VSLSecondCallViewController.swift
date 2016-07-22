//
//  VSLSecondCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLSecondCallViewController: VSLCallViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let TransferInProgress = "TransferInProgressSegue"
            static let UnwindToFirstCall = "UnwindToFirstCallSegue"
            static let UnwindToMainView = "UnwindToMainViewSegue"
        }
    }

    // MARK: - Properties

    var firstCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    // MARK: - Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        firstCall?.addObserver(self, forKeyPath: "callState", options: .New, context: &myContext)
        firstCall?.addObserver(self, forKeyPath: "onHold", options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: "callState")
        firstCall?.removeObserver(self, forKeyPath: "onHold")
    }

    // MARK: - Outlets

    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!

    // MARK: - Actions

    @IBAction override func transferButtonPressed(sender: UIButton) {
        guard let firstCall = firstCall where firstCall.callState == .Confirmed,
            let secondCall = activeCall where firstCall.callState == .Confirmed else { return }

        if firstCall.transferToCall(secondCall) {
            UIDevice.currentDevice().proximityMonitoringEnabled = false
            performSegueWithIdentifier(Configuration.Segues.TransferInProgress, sender: nil)
        }
    }

    override func endCall() {
        if let call = activeCall where call.callState != .Null {
            do {
                try call.hangup()
                self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
            } catch let error {
                DDLogWrapper.logError("Couldn't hangup call: \(error)")
            }
        }
    }

    override func updateUI() {
        super.updateUI()
        if let call = firstCall {
            updateLabels(call: call, statusLabel: firstCallStatusLabel, numberLabel: firstCallNumberLabel)
        }

        // Only enable transferButton if both calls are confirmed.
        transferButton?.enabled = activeCall?.callState == .Confirmed && firstCall?.callState == .Confirmed
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let transferInProgressVC = segue.destinationViewController as? VSLTransferInProgressViewController {
            transferInProgressVC.firstCall = firstCall
            transferInProgressVC.secondCall = activeCall
        } else if let callVC = segue.destinationViewController as? VSLCallViewController {
            // The first call was disconnected, but second call in progress, so show second call as active call.
            callVC.activeCall = activeCall
        }else {
            super.prepareForSegue(segue, sender: sender)
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
        if let call = object as? VSLCall where call == firstCall && call.callState == .Disconnected,
            let activeCall = activeCall where activeCall.callState != .Null {
            dispatch_async(GlobalMainQueue) {
                self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
            return
        }

        if context == &myContext {
            dispatch_async(GlobalMainQueue) {
                if let call = self.activeCall where keyPath == "callState" &&  call.callState == .Disconnected && self.firstCall?.transferStatus != .Unkown  {
                     // If the transfer is in progress, the active call will be Disconnected. Perform the segue.
                     self.performSegueWithIdentifier(Configuration.Segues.TransferInProgress, sender: nil)
                }
                self.updateUI()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}