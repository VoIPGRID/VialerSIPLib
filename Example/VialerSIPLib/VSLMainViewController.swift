//
//  VSLMainViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLMainViewController: UIViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let ShowIncomingCall = "ShowIncomingCallSegue"
        }
    }

    // MARK: - Properties

    private var account: VSLAccount? {
        didSet {
            updateUI()
        }
    }

    private var incomingCall: VSLCall?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(incomingCallNotification(_:)), name: AppDelegate.Configuration.Notifications.IncomingCall, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        account?.addObserver(self, forKeyPath: "accountState", options: .New, context: &myContext)
        updateUI()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        account?.removeObserver(self, forKeyPath: "accountState")
    }

    // MARK: - Outlets

    @IBOutlet weak var registerAccountButton: UIButton!

    // MARK: - Actions

    @IBAction func registerAccountButtonPressed(sender: UIButton) {
        if let _ = account where account!.isRegistered {
            try! account!.unregisterAccount()
            account?.removeObserver(self, forKeyPath: "accountState")
            account = nil
        } else {
            registerAccountWithCompletion()
        }
    }

    // MARK: - Helper functions

    private func updateUI() {
        dispatch_async(GlobalMainQueue) {
            if let account = self.account {
                self.registerAccountButton.setTitle(account.isRegistered ? "Unregister" : "Register", forState: .Normal)
            }  else {
                self.registerAccountButton.setTitle("Register", forState: .Normal)
            }
        }
    }

    private func registerAccountWithCompletion(completion: (() -> ())? = nil) {
        registerAccountButton.enabled = false
        VialerSIPLib.sharedInstance().registerAccountWithUser(SipUser()) { (succes, account) in
            self.account = account
            self.account!.addObserver(self, forKeyPath: "accountState", options: .New, context: &myContext)
            dispatch_async(GlobalMainQueue) {
                self.registerAccountButton.enabled = true
            }
        }
    }

    // MARK: - Segues

    @IBAction func unwindToMainViewController(segue: UIStoryboardSegue) {}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let account = account, let makeCallVC = segue.destinationViewController as? VSLMakeCallViewController {
            makeCallVC.account = account
        } else if let call = incomingCall, let incomingCallVC = segue.destinationViewController as? VSLIncomingCallViewController {
            incomingCallVC.call = call
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let account = object as? VSLAccount where account == self.account {
            updateUI()
        }
    }

    // MARK: - NSNotificationCenter

    func incomingCallNotification(notification: NSNotification) {

        if let call = notification.object as? VSLCall, let accounts =  VialerSIPLib.sharedInstance().accounts() as? [VSLAccount] {
            // When there is another call active, decline incoming call.
            for account in accounts {
                if call != account.firstActiveCall() {
                    try! call.hangup()
                    return
                }
            }
            // Show incoming call view.
            self.incomingCall = call
            dispatch_async(GlobalMainQueue) {
                self.performSegueWithIdentifier(Configuration.Segues.ShowIncomingCall, sender: nil)
            }
        }
    }
}
