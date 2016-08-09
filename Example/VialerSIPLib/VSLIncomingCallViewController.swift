//
//  VSLIncomingCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLIncomingCallViewController: UIViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let UnwindToMainViewController = "UnwindToMainViewControllerSegue"
            static let ShowCall = "ShowCallSegue"
        }
        static let UnwindTime = 2.0
    }

    // MARK: - Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        call?.addObserver(self, forKeyPath: "callState", options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        call?.removeObserver(self, forKeyPath: "callState")
    }

    // MARK: - Properties

    var call: VSLCall? {
        didSet {
            updateUI()
        }
    }

    lazy var ringtone: VSLRingtone = {
        let fileUrl = NSBundle.mainBundle().URLForResource("ringtone", withExtension: "wav")!
        return VSLRingtone.init(ringtonePath: fileUrl)!
    }()

    // MARK: - Outlets

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!

    // MARK: - Actions

    @IBAction func declineButtonPressed(sender: UIButton) {
        try! call?.hangup()
        performSegueWithIdentifier(Configuration.Segues.UnwindToMainViewController, sender: nil)
    }

    @IBAction func acceptButtonPressed(sender: UIButton) {
        if let call = call where call.callState == .Incoming {
            do {
                try call.answer()
                performSegueWithIdentifier(Configuration.Segues.ShowCall, sender: nil)
            } catch let error {
                DDLogWrapper.logError("error answering call: \(error)")
            }
        }
    }

    private func updateUI() {
        if let call = call {
            numberLabel?.text = call.callerNumber
            switch call.callState {
            case .Incoming:
                statusLabel?.text = "Incoming call"
            case .Connecting:
                statusLabel?.text = "Connecting"
            case .Confirmed:
                statusLabel?.text = "Connected"
            case .Disconnected:
                statusLabel?.text = "Disconnected"
            case .Null: fallthrough
            case .Calling: fallthrough
            case .Early:
                statusLabel?.text = "Invalid"
            }

            if call.callState == .Incoming {
                declineButton?.enabled = true
                acceptButton?.enabled = true
                ringtone.start()
            } else {
                ringtone.stop()
                declineButton?.enabled = false
                acceptButton?.enabled = false
            }
        } else {
            numberLabel?.text = ""
            statusLabel?.text = ""
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let callViewController = segue.destinationViewController as? VSLCallViewController {
            callViewController.activeCall = call
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext {
            dispatch_async(GlobalMainQueue) {
                self.updateUI()
            }

            if let call = object as? VSLCall where call.callState == .Disconnected {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Configuration.UnwindTime * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier(Configuration.Segues.UnwindToMainViewController, sender: nil)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
