//
//  VSLMainViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLMainViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {


    // MARK: - Configuration

    fileprivate struct Configuration {
        struct Segues {
            static let ShowIncomingCall = "ShowIncomingCallSegue"
            static let DirectlyShowActiveCallControllerSegue = "DirectlyShowActiveCallControllerSegue"
        }
    }

    // MARK: - Properties

    fileprivate var account: VSLAccount {
        get {
            return AppDelegate.shared.account
        }
    }

    fileprivate var activeCall: VSLCall?

    fileprivate var transportPickerData: [String] = [String]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        transportPickerData = ["UDP", "TCP", "TLS"]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(incomingCallNotification(_:)),
                                               name: AppDelegate.Configuration.Notifications.incomingCall,
                                               object: nil)
        // If we are CallKit compatible
        if #available(iOS 10.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(directlyShowActiveCallController(_:)),
                                                   name: Notification.Name.CallKitProviderDelegateOutboundCallStarted,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(directlyShowActiveCallController(_:)),
                                                   name: Notification.Name.CallKitProviderDelegateInboundCallAccepted,
                                                   object: nil)
        }

        account.addObserver(self, forKeyPath: #keyPath(VSLAccount.accountState), options: .new, context: &myContext)
        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        account.removeObserver(self, forKeyPath: #keyPath(VSLAccount.accountState))

        NotificationCenter.default.removeObserver(self,
                                                  name:AppDelegate.Configuration.Notifications.incomingCall,
                                                  object: nil)

        if #available(iOS 10.0, *) {
            NotificationCenter.default.removeObserver(self,
                                                      name: Notification.Name.CallKitProviderDelegateOutboundCallStarted,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: Notification.Name.CallKitProviderDelegateInboundCallAccepted,
                                                      object: nil)
        }
    }

    // MARK: - Outlets

    @IBOutlet weak var registerAccountButton: UIButton!
    @IBOutlet weak var transportPicker: UIPickerView!
    @IBOutlet weak var useVideoSwitch: UISwitch!
    
    // MARK: - Actions
    @IBAction func useVideoSwichPressed(_ sender: UISwitch) {
        let prefs = UserDefaults.standard
        prefs.set(sender.isOn, forKey: "useVideo")
        account.removeObserver(self, forKeyPath: #keyPath(VSLAccount.accountState))
        VialerSIPLib.sharedInstance().removeEndpoint()
        AppDelegate.shared.setupVialerEndpoint()
        AppDelegate.shared.setupAccount()
        account.addObserver(self, forKeyPath: #keyPath(VSLAccount.accountState), options: .new, context: &myContext)
    }

    @IBAction func registerAccountButtonPressed(_ sender: UIButton) {
        if account.isRegistered {
            try! account.unregisterAccount()
        } else {
            registerAccount()
        }
    }

    // MARK: - TransportType Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return transportPickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return transportPickerData[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let prefs = UserDefaults.standard
        prefs.set(transportPickerData[row], forKey: "transportType")
        account.removeObserver(self, forKeyPath: #keyPath(VSLAccount.accountState))
        VialerSIPLib.sharedInstance().removeEndpoint()
        AppDelegate.shared.setupVialerEndpoint()
        AppDelegate.shared.setupAccount()
        account.addObserver(self, forKeyPath: #keyPath(VSLAccount.accountState), options: .new, context: &myContext)
    }

    // MARK: - Helper functions

    fileprivate func updateUI() {
        DispatchQueue.main.async {
            self.registerAccountButton.setTitle(self.account.isRegistered ? "Unregister" : "Register", for: UIControlState())
        }

        let prefs = UserDefaults.standard
        let useVideo = prefs.bool(forKey: "useVideo")
        DispatchQueue.main.async {
            self.useVideoSwitch.setOn(useVideo, animated: true)
        }

        let transportType = prefs.string(forKey: "transportType")
        if transportType != nil, let defaultRowIndex = transportPickerData.index(of: transportType!) {
            transportPicker.selectRow(defaultRowIndex, inComponent: 0, animated: true)
        }

    }

    fileprivate func registerAccount() {
        registerAccountButton.isEnabled = false

        account.register{ (success, error) in
            DispatchQueue.main.async {
                self.registerAccountButton.isEnabled = true
            }
        }
    }

    // MARK: - Segues

    @IBAction func unwindToMainViewController(_ segue: UIStoryboardSegue) {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let callViewController = segue.destination as? VSLCallViewController {
            callViewController.activeCall = activeCall

        } else if let makeCallVC = segue.destination as? VSLMakeCallViewController {
            makeCallVC.account = account

        } else if let call = activeCall, let incomingCallVC = segue.destination as? VSLIncomingCallViewController {
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

    @objc func incomingCallNotification(_ notification: Notification) {
        guard let call = notification.userInfo?[VSLNotificationUserInfoCallKey] as? VSLCall else { return }
        // When there is another call active, decline incoming call.
        if call != account.firstActiveCall() {
            try! call.hangup()
            return
        }
        // Show incoming call view.
        activeCall = call
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: Configuration.Segues.ShowIncomingCall, sender: nil)
        }
    }

    // When an outbound call is requested trough CallKit, show the VSLCallViewController directly.
    @objc func directlyShowActiveCallController(_ notification: Notification) {
        guard let call = notification.userInfo?[VSLNotificationUserInfoCallKey] as? VSLCall else { return }
        activeCall = call
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: Configuration.Segues.DirectlyShowActiveCallControllerSegue, sender: nil)
        }
    }
}

