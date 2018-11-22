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

    var account: VSLAccount!

    var call: VSLCall?
    var callManager: VSLCallManager!

    fileprivate var number: String = "\(Keys.NumberToCall)"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        callManager = VialerSIPLib.sharedInstance().callManager
    }

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
        numberToDialLabel.text = number
        updateUI()
    }

    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        number = number.substring(to: number.characters.index(number.endIndex, offsetBy: -1))
        numberToDialLabel.text = number
        updateUI()
    }

    @IBAction func callButtonPressed(_ sender: UIButton) {
        self.callButton.isEnabled = false
        if account.isRegistered {
            setupCall()
        } else {
            account.register { (success, error) in
                self.setupCall()

            }
        }
    }

    fileprivate func setupCall() {
        self.callManager.startCall(toNumber: number, for: account ) { (call, error) in
            if error != nil {
                DDLogWrapper.logError("Could not start call")
            } else {
                self.call = call
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: Configuration.Segues.ShowCallViewController, sender: nil)
                }
            }
        }
    }

    func updateUI() {
        callButton?.isEnabled = number != ""
        deleteButton?.isEnabled = number != ""
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let callViewController = segue.destination as? VSLCallViewController {
            callViewController.activeCall = call
        }
    }

}
