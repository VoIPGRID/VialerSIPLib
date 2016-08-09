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

    var dtmfSent: String {
        set {
            dtmfLabel.text = newValue
        }
        get {
            return dtmfLabel.text!
        }
    }

    // MARK: Lifecycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        call?.addObserver(self, forKeyPath: "callState", options: .New, context: &myContext)
    }

    override func viewWillDisappear(animated: Bool) {
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

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        delegate?.dismissKeypadViewController()
    }

    @IBAction func keypadNumberPressed(sender: AnyObject) {
        if let call = call where call.callState == .Confirmed, let button = sender as? UIButton {
            do {
                try call.sendDTMF(button.currentTitle!)
                dtmfSent = dtmfSent + button.currentTitle!
            } catch let error {
                DDLogWrapper.logError("Error sending DTMF: \(error)")
            }
        }
    }

    private func updateUI() {
        if let call = call, let label = numberLabel {
            label.text = call.callerNumber
        } else {
            numberLabel?.text = ""
        }
    }

    // MARK: - KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &myContext , let call = object as? VSLCall where call.callState == .Disconnected {
            dispatch_async(GlobalMainQueue) {
                self.delegate?.dismissKeypadViewController()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
