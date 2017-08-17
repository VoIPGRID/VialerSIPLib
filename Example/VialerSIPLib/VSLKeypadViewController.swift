//
//  VSLKeypadViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

protocol VSLKeypadViewControllerDelegate {
    func dismissKeypadViewController()
}

private var myContext = 0

class VSLKeypadViewController: UIViewController {

    // MARK: - Properties

    var call: VSLCall? {
        didSet {
            updateUI()
        }
    }
    var delegate: VSLKeypadViewControllerDelegate?

    var callManager: VSLCallManager!

    var dtmfSent: String {
        set {
            dtmfLabel.text = newValue
        }
        get {
            return dtmfLabel.text!
        }
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        callManager = VialerSIPLib.sharedInstance().callManager
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        call?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        call?.removeObserver(self, forKeyPath: "callState")
    }

    // MARK: - Outlets

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var dtmfLabel: UILabel! {
        didSet {
            dtmfLabel.text = ""
        }
    }

    // MARK: - Actions

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.dismissKeypadViewController()
    }

    @IBAction func keypadNumberPressed(_ sender: AnyObject) {
        guard let call = call, call.callState == .confirmed, let button = sender as? UIButton else { return }
        callManager.sendDTMF(for: call, character: button.currentTitle!) { error in
            if error != nil {
                DDLogWrapper.logError("Error sending DTMF: \(error ?? "Unknown Error" as! Error)")
            } else {
                DispatchQueue.main.async {
                    self.dtmfSent = self.dtmfSent + button.currentTitle!
                }
            }
        }
    }

    fileprivate func updateUI() {
        if let call = call, let label = numberLabel {
            label.text = call.callerNumber
        } else {
            numberLabel?.text = ""
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext , let call = object as? VSLCall , call.callState == .disconnected {
            DispatchQueue.main.async {
                self.delegate?.dismissKeypadViewController()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
