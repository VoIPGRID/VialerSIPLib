//
//  VSLMakeCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

class VSLMakeCallViewController: UIViewController {

    // MARK: - Configuration

    private struct Configuration {
        struct Segues {
            static let UnwindToMainViewController = "UnwindToMainViewControllerSegue"
            static let ShowCallViewController = "ShowCallViewControllerSegue"
        }
    }

    // MARK: - Properties

    var account: VSLAccount?
    var call: VSLCall?

    private var number: String {
        set {
            numberToDialLabel?.text = newValue
            callButton?.enabled = newValue != ""
            deleteButton?.enabled = newValue != ""
        }
        get {
            return numberToDialLabel.text!
        }
    }

    // MARK: - Lifecycle

    override func viewWillAppear(animated: Bool) {
        UIDevice.currentDevice().proximityMonitoringEnabled = false
        updateUI()
    }

    // MARK: - Outlets

    @IBOutlet weak var numberToDialLabel: UILabel! {
        didSet {
            numberToDialLabel.text = "\(Keys.NumberToCall)"
        }
    }

    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    // MARK: - Actions

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier(Configuration.Segues.UnwindToMainViewController, sender: nil)
    }

    @IBAction func keypadButtonPressed(sender: UIButton) {
        number = number + sender.currentTitle!
    }

    @IBAction func deleteButtonPressed(sender: UIButton) {
        number = number.substringToIndex(number.endIndex.advancedBy(-1))
    }

    @IBAction func callButtonPressed(sender: UIButton) {
        self.callButton.enabled = false
        UIDevice.currentDevice().proximityMonitoringEnabled = true
        if let account = account where account.isRegistered {
            setupCall()
        } else {
            VialerSIPLib.sharedInstance().registerAccountWithUser(SipUser()) { (success, account) in
                if let account = account where success {
                    self.account = account
                    self.setupCall()
                } else {
                    UIDevice.currentDevice().proximityMonitoringEnabled = false
                }
            }
        }
    }

    private func setupCall() {
        self.account?.callNumber(number) { (error, call) in
            self.call = call
            dispatch_async(GlobalMainQueue) {
                self.performSegueWithIdentifier(Configuration.Segues.ShowCallViewController, sender: nil)
            }
        }
    }

    func updateUI() {
        callButton?.enabled = number != ""
        deleteButton?.enabled = number != ""
    }

    // MARK: - Segues

    @IBAction func unwindToMakeCallViewController(segue: UIStoryboardSegue) {}

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let callViewController = segue.destinationViewController as? VSLCallViewController {
            callViewController.activeCall = call
        }
    }

}
