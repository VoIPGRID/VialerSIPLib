//
//  VSLSecondCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLSecondCallViewController: VSLCallViewController {

    // MARK: - Configuration

    fileprivate struct Configuration {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        _ = stopObservingAfterCheckCallStates()
        firstCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
        firstCall?.addObserver(self, forKeyPath: "onHold", options: .new, context: &myContext)
        firstCall?.addObserver(self, forKeyPath: "transferStatus", options: .new, context: &myContext)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: "callState")
        firstCall?.removeObserver(self, forKeyPath: "onHold")
        firstCall?.removeObserver(self, forKeyPath: "transferStatus")
    }

    // MARK: - Outlets

    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!

    // MARK: - Actions

    @IBAction override func transferButtonPressed(_ sender: UIButton) {
        guard let firstCall = firstCall, firstCall.callState == .confirmed,
            let secondCall = activeCall, firstCall.callState == .confirmed else { return }

        if firstCall.transfer(to: secondCall) {
            callManager.end(firstCall) { error in
                if error != nil {
                    DDLogWrapper.logError("Error hanging up call: \(error!)")
                }
            }
            callManager.end(secondCall) { error in
                if error != nil {
                    DDLogWrapper.logError("Error hanging up call: \(error!)")
                }
            }
            performSegue(withIdentifier: Configuration.Segues.TransferInProgress, sender: nil)
        }
    }

    override func endCall() {
        guard let call = activeCall, call.callState != .null else { return }

        callManager.end(call) { error in
            if error != nil {
                DDLogWrapper.logError("Could not end call: \(error!))")
            } else {
                self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
        }
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        guard let call = activeCall, call.callState != .disconnected else {
            self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            return
        }
        callManager.end(call) { error in
            if error != nil {
                DDLogWrapper.logError("Could not end call: \(error!)")
            } else {
                self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
        }
    }


    // MARK: - Helper functions

    override func updateUI() {
        super.updateUI()
        if let call = firstCall {
            updateLabels(call: call, statusLabel: firstCallStatusLabel, numberLabel: firstCallNumberLabel)
        }

        // Only enable transferButton if both calls are confirmed.
        transferButton?.isEnabled = activeCall?.callState == .confirmed && firstCall?.callState == .confirmed
    }

    /**
     Check the current state of the calls and perform segue if appropriate.

     If one of the calls is disconnected, go back to screen with one call active.
     If both calls are disconnected, return to main screen.

     - returns: Bool if the observing should propagate to super class.
     */
    fileprivate func stopObservingAfterCheckCallStates() -> Bool {
        // If the first call is disconnected and the second call is in progress, unwind to CallViewController.
        // In prepare the second call will be set as the activeCall.
        guard let firstCall = firstCall, let activeCall = activeCall else { return false }

        if (firstCall.callState != .disconnected && activeCall.callState == .disconnected) || (firstCall.callState == .disconnected && activeCall.callState != .disconnected)  {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Configuration.Segues.UnwindToFirstCall, sender: nil)
            }
            return true
        } else if (firstCall.callState == .disconnected && activeCall.callState == .disconnected) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Configuration.Segues.UnwindToMainView, sender: nil)
            }
            return true
        }
        return false
    }

    // MARK: - Segues

    @IBAction func unwindToSecondCallViewController(_ segue: UIStoryboardSegue) {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let transferInProgressVC = segue.destination as? VSLTransferInProgressViewController {
            transferInProgressVC.firstCall = firstCall
            transferInProgressVC.secondCall = activeCall
        } else if let callVC = segue.destination as? VSLCallViewController {
            // The first call was disconnected, but second call in progress, so show second call as active call.
            if let call = firstCall, call.callState == .disconnected {
                callVC.activeCall = activeCall
            }
        }else {
            super.prepare(for: segue, sender: sender)
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if stopObservingAfterCheckCallStates() {
            return
        }

        if context == &myContext {
            DispatchQueue.main.async {
                self.updateUI()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
