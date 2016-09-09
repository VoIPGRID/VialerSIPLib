//
//  VSLMakeCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

class VSLMakeCallViewController: UIViewController {

    // MARK: - Configuration

    fileprivate struct Configuration {
        struct Segues {
            static let UnwindToMainViewController = "UnwindToMainViewControllerSegue"
            static let ShowCallViewController = "ShowCallViewControllerSegue"
        }
    }

    // MARK: - Properties

    var account: VSLAccount?
    var call: VSLCall?

    fileprivate var number: String {
        set {
            numberToDialLabel?.text = newValue
            callButton?.isEnabled = newValue != ""
            deleteButton?.isEnabled = newValue != ""
        }
        get {
            return numberToDialLabel.text!
        }
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        UIDevice.current.isProximityMonitoringEnabled = false
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

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Configuration.Segues.UnwindToMainViewController, sender: nil)
    }

    @IBAction func keypadButtonPressed(_ sender: UIButton) {
        number = number + sender.currentTitle!
    }

    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        number = number.substring(to: number.characters.index(number.endIndex, offsetBy: -1))
    }

    @IBAction func callButtonPressed(_ sender: UIButton) {
        self.callButton.isEnabled = false
        UIDevice.current.isProximityMonitoringEnabled = true
        if let account = account, account.isRegistered {
            setupCall()
        } else {
            VialerSIPLib.sharedInstance().registerAccount(with: SipUser()) { (success, account) in
                if let account = account, success {
                    self.account = account
                    self.setupCall()
                } else {
                    UIDevice.current.isProximityMonitoringEnabled = false
                }
            }
        }
    }

    fileprivate func setupCall() {
        self.account?.callNumber(number) { (error, call) in
            self.call = call
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Configuration.Segues.ShowCallViewController, sender: nil)
            }
        }
    }

    func updateUI() {
        callButton?.isEnabled = number != ""
        deleteButton?.isEnabled = number != ""
    }

    // MARK: - Segues

    @IBAction func unwindToMakeCallViewController(_ segue: UIStoryboardSegue) {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let callViewController = segue.destination as? VSLCallViewController {
            callViewController.activeCall = call
        }
    }

}
