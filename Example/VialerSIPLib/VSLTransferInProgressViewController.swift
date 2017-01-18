//
//  VSLTransferInProgressViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import UIKit

private var myContext = 0

class VSLTransferInProgressViewController: UIViewController {

    // MARK: - Configuration

    struct Configuration {
        struct Segues {
            static let UnwindToCallViewController = "UnwindToCallViewControllerSegue"
            static let UnwindToSecondCallViewController = "UnwindToSecondCallViewControllerSegue"
            static let ShowEndCallSegue = "ShowEndCallSegue"
        }
        static let UnwindTiming = 2.0
    }

    // MARK: - Properties

    var firstCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    var secondCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        firstCall?.addObserver(self, forKeyPath: "transferStatus", options: .new, context: &myContext)
        checkIfViewCanBeDismissed()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        firstCall?.removeObserver(self, forKeyPath: "transferStatus")
    }

    // MARK: - Outlets

    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var secondCallNumberLabel: UILabel!
    @IBOutlet weak var transferStatusLabel: UILabel!

    // MARK: - Actions

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        self.dismissView()
    }

    func updateUI() {
        if let call = firstCall, let label = firstCallNumberLabel, let statusLabel = transferStatusLabel {
            label.text = call.callerNumber!
            switch call.transferStatus {
            case .unkown: fallthrough
            case .initialized:
                statusLabel.text = "Transfer requested for"
            case .trying:
                statusLabel.text = "Transfer in progress to"
            case .accepted:
                statusLabel.text = "Successfully connected with"
            case .rejected:
                statusLabel.text = "Transfer rejected for"
            }
        }

        if let call = secondCall, let label = secondCallNumberLabel {
            label.text = call.callerNumber!
        }
    }

    fileprivate func prepareForDismissing() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Configuration.UnwindTiming * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            DispatchQueue.main.async {
                self.dismissView()
            }
        }
    }

    fileprivate func dismissView() {
        // Rewind one step if transfer was rejected.
        if firstCall?.transferStatus == .rejected {
            performSegue(withIdentifier: Configuration.Segues.UnwindToSecondCallViewController, sender: nil)
        } else {
            performSegue(withIdentifier: Configuration.Segues.ShowEndCallSegue, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let endOfCallVC = segue.destination as? VSLEndOfCallViewController {
            endOfCallVC.duration = firstCall!.connectDuration
            endOfCallVC.mos = firstCall!.mos
            endOfCallVC.mbsUsed = firstCall!.totalMBsUsed
            endOfCallVC.codec = firstCall!.activeCodec
        }
    }

    fileprivate func checkIfViewCanBeDismissed() {
        if let call = firstCall, call.transferStatus == .accepted || call.transferStatus == .rejected {
            prepareForDismissing()
        }
    }
    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if keyPath == "transferStatus" {
                DispatchQueue.main.async {
                    self.updateUI()
                }
                checkIfViewCanBeDismissed()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
