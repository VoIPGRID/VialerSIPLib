//
//  VSLMainViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLMainViewController: UIViewController {

    // MARK: - Configuration

    fileprivate struct Configuration {
        struct Segues {
            static let ShowIncomingCall = "ShowIncomingCallSegue"
        }
    }

    // MARK: - Properties

    fileprivate var account: VSLAccount? {
        didSet {
            updateUI()
        }
    }

    fileprivate var incomingCall: VSLCall?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(incomingCallNotification(_:)), name: NSNotification.Name(rawValue: AppDelegate.Configuration.Notifications.IncomingCall), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        account?.addObserver(self, forKeyPath: "accountState", options: .new, context: &myContext)
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        account?.removeObserver(self, forKeyPath: "accountState")
    }

    // MARK: - Outlets

    @IBOutlet weak var registerAccountButton: UIButton!

    // MARK: - Actions

    @IBAction func registerAccountButtonPressed(_ sender: UIButton) {
        if let _ = account, account!.isRegistered {
            try! account!.unregisterAccount()
            account?.removeObserver(self, forKeyPath: "accountState")
            account = nil
        } else {
            registerAccountWithCompletion()
        }
    }

    // MARK: - Helper functions

    fileprivate func updateUI() {
        DispatchQueue.main.async {
            if let account = self.account {
                self.registerAccountButton.setTitle(account.isRegistered ? "Unregister" : "Register", for: UIControlState())
            }  else {
                self.registerAccountButton.setTitle("Register", for: UIControlState())
            }
        }
    }

    fileprivate func registerAccountWithCompletion(_ completion: (() -> ())? = nil) {
        registerAccountButton.isEnabled = false
        VialerSIPLib.sharedInstance().registerAccount(with: SipUser()) { (succes, account) in
            self.account = account
            self.account!.addObserver(self, forKeyPath: "accountState", options: .new, context: &myContext)
            DispatchQueue.main.async {
                self.registerAccountButton.isEnabled = true
            }
        }
    }

    // MARK: - Segues

    @IBAction func unwindToMainViewController(_ segue: UIStoryboardSegue) {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let account = account, let makeCallVC = segue.destination as? VSLMakeCallViewController {
            makeCallVC.account = account
        } else if let call = incomingCall, let incomingCallVC = segue.destination as? VSLIncomingCallViewController {
            incomingCallVC.call = call
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let account = object as? VSLAccount, account == self.account {
            updateUI()
        }
    }

    // MARK: - NSNotificationCenter

    func incomingCallNotification(_ notification: Notification) {

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
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Configuration.Segues.ShowIncomingCall, sender: nil)
            }
        }
    }
}
