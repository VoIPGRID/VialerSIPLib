//
//  VSLCallViewController.swift
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

import AVFoundation
import MediaPlayer
import UIKit

private var myContext = 0

class VSLCallViewController: UIViewController, VSLKeypadViewControllerDelegate {

    // MARK: - Configuration

    fileprivate struct Configuration {
        struct Timing {
            static let UnwindTime = 2.0
            static let connectDurationInterval = 1.0
        }
        struct Segues {
            static let UnwindToMainViewController = "UnwindToMainViewControllerSegue"
            static let ShowKeypad = "ShowKeypadSegue"
            static let SetupTransfer = "SetupTransferSegue"
        }
    }

    // MARK: - Properties
    var callManager: VSLCallManager!

    var activeCall: VSLCall? {
        didSet {
            updateUI()
        }
    }

    var connectDurationTimer: Timer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        callManager = VialerSIPLib.sharedInstance().callManager
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.isProximityMonitoringEnabled = true
        updateUI()
        startConnectDurationTimer()
        activeCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
        activeCall?.addObserver(self, forKeyPath: "onHold", options: .new, context: &myContext)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NSNotification.Name(rawValue: VSLAudioControllerAudioInterrupted), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.isProximityMonitoringEnabled = false
        connectDurationTimer?.invalidate()
        activeCall?.removeObserver(self, forKeyPath: "callState")
        activeCall?.removeObserver(self, forKeyPath: "onHold")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: VSLAudioControllerAudioInterrupted), object: nil)
    }

    // MARK: - Outlets

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var holdButton: UIButton!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var keypadButton: UIButton!

    // MARK: - Actions

    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        endCall()
    }

    @IBAction func muteButtonPressed(_ sender: UIButton) {
        guard let call = activeCall, call.callState != .disconnected else { return }

        callManager.toggleMute(for: call) { error in
            if error != nil {
                DDLogWrapper.logError("Error muting call: \(error)")
            }
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }

    @IBAction func speakerButtonPressed(_ sender: UIButton) {
        if callManager.audioController.hasBluetooth {
            // We add the MPVolumeView to the view without any size, we just need it so we can push the button in code.
            let volumeView = MPVolumeView(frame: CGRect())
            view.addSubview(volumeView)
            for view in volumeView.subviews {
                if let button = view as? UIButton {
                    button.sendActions(for: .touchUpInside)
                }
            }
        } else {
            callManager.audioController.output = callManager.audioController.output == .speaker ? .other : .speaker
            updateUI()
        }
    }

    @IBAction func holdButtonPressed(_ sender: UIButton) {
        guard let call = activeCall, call.callState != .disconnected else { return }

        callManager.toggleHold(for: call) { error in
            if error != nil {
                DDLogWrapper.logError("Error holding call: \(error)")
            }
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
    }

    @IBAction func keypadButtonPressed(_ sender: UIButton) {
        if let call = activeCall, call.callState == .confirmed {
            performSegue(withIdentifier: Configuration.Segues.ShowKeypad, sender: nil)
        }
    }

    @IBAction func transferButtonPressed(_ sender: UIButton) {
        guard let call = activeCall, call.callState == .confirmed else { return }

        // If the call is on hold, perform segue, otherwise, try put on hold before segue.
        if call.onHold {
            performSegue(withIdentifier: Configuration.Segues.SetupTransfer, sender: nil)
            return
        }

        callManager.toggleHold(for: call) { error in
            if error != nil {
                DDLogWrapper.logError("Error holding current call: \(error)")
                return
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: Configuration.Segues.SetupTransfer, sender: nil)
            }
        }
    }

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        guard let call = activeCall, call.callState != .disconnected else { return }

        callManager.end(call) { error in
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    func endCall() {
        guard let call = activeCall, call.callState != .disconnected else { return }

        callManager.end(call) { error in
            if error != nil {
                DDLogWrapper.logError("error hanging up call(\(call.uuid.uuidString)): \(error)")
            }
        }
    }

    func updateUI() {
        guard let call = activeCall else { return }
        updateLabels(call: call, statusLabel: statusLabel, numberLabel: numberLabel)

        switch call.callState {
        case .incoming: fallthrough
        case .null: fallthrough
        case .disconnected:
            // No Buttons enabled
            muteButton?.isEnabled = false
            keypadButton?.isEnabled = false
            transferButton?.isEnabled = false
            holdButton?.isEnabled = false
            hangupButton?.isEnabled = false
            speakerButton?.isEnabled = false
        case .calling: fallthrough
        case .early: fallthrough
        case .connecting:
            // Speaker & hangup can be enabled
            muteButton?.isEnabled = false
            keypadButton?.isEnabled = false
            transferButton?.isEnabled = false
            holdButton?.isEnabled = false
            hangupButton?.isEnabled = true
            speakerButton?.isEnabled = true
        case .confirmed:
            // All buttons enabled
            muteButton?.isEnabled = !call.onHold
            muteButton?.setTitle(call.muted ? "Muted" : "Mute", for: UIControlState())
            keypadButton?.isEnabled = !call.onHold
            transferButton?.isEnabled = true
            holdButton?.isEnabled = true
            holdButton?.setTitle(call.onHold ? "On Hold" : "Hold", for: UIControlState())
            hangupButton?.isEnabled = true
            speakerButton?.isEnabled = true
        }

        guard let callManager = callManager else { return }
        if (callManager.audioController.hasBluetooth) {
            speakerButton?.setTitle("Audio", for: UIControlState())
        } else {
            speakerButton?.setTitle(callManager.audioController.output == .speaker ? "On Speaker" : "Speaker", for: UIControlState())
        }
    }

    /**
     Helper function to update the UI for the specific call.

     - parameter call:        VSLCall that stores the status.
     - parameter statusLabel: UILabel that presents the status.
     - parameter numberLabel: UILabel that presents the number.
     */
    func updateLabels(call: VSLCall, statusLabel: UILabel?, numberLabel: UILabel?) {
        var numberLabelText: String {
            if let name = call.callerName, name != "" {
                return "\(name)\n\(call.callerNumber!)"
            } else {
                return call.isIncoming ? call.callerNumber! : call.numberToCall
            }
        }

        numberLabel?.text = numberLabelText
        switch call.callState {
        case .null:
            statusLabel?.text = "Not started"
        case .calling:
            statusLabel?.text = "Calling..."
        case .incoming: break
        case .early: fallthrough
        case .connecting:
            statusLabel?.text = "Connecting..."
        case .confirmed:
            if call.onHold {
                statusLabel?.text = "ON HOLD"
            } else {
                let dateComponentsFormatter = DateComponentsFormatter()
                dateComponentsFormatter.zeroFormattingBehavior = .pad
                dateComponentsFormatter.allowedUnits = [.minute, .second]
                statusLabel?.text = "\(dateComponentsFormatter.string(from: call.connectDuration)!)"
            }
        case .disconnected:
            statusLabel?.text = "Disconnected"
            connectDurationTimer?.invalidate()
        }
    }

    fileprivate func startConnectDurationTimer() {
        if connectDurationTimer == nil || !connectDurationTimer!.isValid {
            connectDurationTimer = Timer.scheduledTimer(timeInterval: Configuration.Timing.connectDurationInterval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
        }
    }

    // MARK: - Segues

    @IBAction func unwindToFirstCallInProgressSegue(_ segue: UIStoryboardSegue) {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let keypadVC = segue.destination as? VSLKeypadViewController {
            keypadVC.call = activeCall
            keypadVC.delegate = self
        } else if let transferCallVC = segue.destination as? VSLTransferCallViewController {
            transferCallVC.currentCall = activeCall
        }
    }

    // MARK: - KVO

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if let call = object as? VSLCall, call.callState == .disconnected {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Configuration.Timing.UnwindTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                    self.performSegue(withIdentifier: Configuration.Segues.UnwindToMainViewController, sender: nil)
                }
            }
            DispatchQueue.main.async {
                self.updateUI()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - VSLKeypadViewControllerDelegate

    func dismissKeypadViewController() {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
