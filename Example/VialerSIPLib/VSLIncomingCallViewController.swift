//
//  VSLIncomingCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLIncomingCallViewController: UIViewController {

    // MARK: - Configuration

    fileprivate struct Configuration {
        struct Segues {
            static let UnwindToMainViewController = "UnwindToMainViewControllerSegue"
            static let ShowCall = "ShowCallSegue"
        }
        static let UnwindTime = 2.0
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        call?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
    }

    override func viewWillDisappear(_ animated: Bool) {
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
        let fileUrl = Bundle.main.url(forResource: "ringtone", withExtension: "wav")!
        return VSLRingtone.init(ringtonePath: fileUrl)!
    }()

    // MARK: - Outlets

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!

    // MARK: - Actions

    @IBAction func declineButtonPressed(_ sender: UIButton) {
        try! call?.hangup()
        performSegue(withIdentifier: Configuration.Segues.UnwindToMainViewController, sender: nil)
    }

    @IBAction func acceptButtonPressed(_ sender: UIButton) {
        if let call = call, call.callState == .incoming {
            do {
                try call.answer()
                performSegue(withIdentifier: Configuration.Segues.ShowCall, sender: nil)
            } catch let error {
                DDLogWrapper.logError("error answering call: \(error)")
            }
        }
    }

    fileprivate func updateUI() {
        if let call = call {
            numberLabel?.text = call.callerNumber
            switch call.callState {
            case .incoming:
                statusLabel?.text = "Incoming call"
            case .connecting:
                statusLabel?.text = "Connecting"
            case .confirmed:
                statusLabel?.text = "Connected"
            case .disconnected:
                statusLabel?.text = "Disconnected"
            case .null: fallthrough
            case .calling: fallthrough
            case .early:
                statusLabel?.text = "Invalid"
            }

            if call.callState == .incoming {
                declineButton?.isEnabled = true
                acceptButton?.isEnabled = true
                ringtone.start()
            } else {
                ringtone.stop()
                declineButton?.isEnabled = false
                acceptButton?.isEnabled = false
            }
        } else {
            numberLabel?.text = ""
            statusLabel?.text = ""
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let callViewController = segue.destination as? VSLCallViewController {
            callViewController.activeCall = call
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            DispatchQueue.main.async {
                self.updateUI()
            }

            if let call = object as? VSLCall , call.callState == .disconnected {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Configuration.UnwindTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                    self.performSegue(withIdentifier: Configuration.Segues.UnwindToMainViewController, sender: nil)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
