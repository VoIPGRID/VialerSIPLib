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
        stopObservingAfterCheckCallStates()
        firstCall?.addObserver(self, forKeyPath: "callState", options: .New, context: &myContext)
        firstCall?.addObserver(self, forKeyPath: "onHold", options: .New, context: &myContext)
        firstCall?.addObserver(self, forKeyPath: "transferStatus", options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: "callState")
        firstCall?.removeObserver(self, forKeyPath: "onHold")
        firstCall?.removeObserver(self, forKeyPath: "transferStatus")
    }

    // MARK: - Outlets

    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!

    // MARK: - Actions

    @IBAction override func transferButtonPressed(sender: UIButton) {
        guard let firstCall = firstCall where firstCall.callState == .Confirmed,
            let secondCall = activeCall where firstCall.callState == .Confirmed else { return }

        if firstCall.transferToCall(secondCall) {
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

    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {

        // Hangup active Call if it is not disconnected.
        if let call = activeCall where call.callState != .Disconnected {
            do {
                try call.hangup()
                self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
            } catch let error {
                DDLogWrapper.logError("Couldn't hangup call: \(error)")
            }
        } else {
            self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
        }
    }


    // MARK: - Helper functions

    override func updateUI() {
        super.updateUI()
        if let call = firstCall {
            updateLabels(call: call, statusLabel: firstCallStatusLabel, numberLabel: firstCallNumberLabel)
        }

        // Only enable transferButton if both calls are confirmed.
        transferButton?.enabled = activeCall?.callState == .Confirmed && firstCall?.callState == .Confirmed
    }

    /**
     Check the current state of the calls and perform segue if appropriate. 
     
     If one of the calls is disconnected, go back to screen with one call active.
     If both calls are disconnected, return to main screen.

     - returns: Bool if the observing should propagate to super class.
     */
    private func stopObservingAfterCheckCallStates() -> Bool {
        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
        guard let firstCall = firstCall, let activeCall = activeCall else { return false }

        if (firstCall.callState != .Disconnected && activeCall.callState == .Disconnected) || (firstCall.callState == .Disconnected && activeCall.callState != .Disconnected)  {
            dispatch_async(GlobalMainQueue) {
                self.performSegueWithIdentifier(Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
            return true
        } else if (firstCall.callState == .Disconnected && activeCall.callState == .Disconnected) {
            dispatch_async(GlobalMainQueue) {
                self.performSegueWithIdentifier(Configuration.Segues.UnwindToMainView, sender: nil)
            }
            return true
        }
        return false
    }

    // MARK: - Segues

    @IBAction func unwindToSecondCallViewController(segue: UIStoryboardSegue) {}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let transferInProgressVC = segue.destinationViewController as? VSLTransferInProgressViewController {
            transferInProgressVC.firstCall = firstCall
            transferInProgressVC.secondCall = activeCall
        } else if let callVC = segue.destinationViewController as? VSLCallViewController {
            // The first call was disconnected, but second call in progress, so show second call as active call.
            if let call = firstCall where call.callState == .Disconnected {
                callVC.activeCall = activeCall
            }
        }else {
            super.prepareForSegue(segue, sender: sender)
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        if stopObservingAfterCheckCallStates() {
            return
        }

        if context == &myContext {
            dispatch_async(GlobalMainQueue) {
                self.updateUI()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}