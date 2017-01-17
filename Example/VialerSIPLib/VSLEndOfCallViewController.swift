//
//  VSLEndOfCallViewController.swift
//  Copyright © 2017 Devhouse Spindle. All rights reserved.
//

import Foundation
import UIKit

class VSLEndOfCallViewController: UIViewController {
    // MARK: - Configuration
    
    fileprivate struct Configuration {
        struct Timing {
            static let UnwindTime = 5.0
        }
        struct Segues {
            static let UnwindToMainViewController = "UnwindToMainViewControllerSegue"
        }
    }
    
    // MARK: - Properties
    var duration : TimeInterval = 0.0
    var codec : String = ""
    var mbsUsed : Float = 0.0
    var mos : Float = 0.0
    
    // MARK: - Outlets
    @IBOutlet weak var callDurationLabel: UILabel!
    @IBOutlet weak var codecUsedLabel: UILabel!
    @IBOutlet weak var mosLabel: UILabel!
    @IBOutlet weak var MBUsedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callDurationLabel.text = getDuration(interval: duration)
        codecUsedLabel.text = codec
        mosLabel.text = NSString(format: "%.2f", mos) as String
        MBUsedLabel.text = NSString(format: "%.2f", mbsUsed) as String
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Configuration.Timing.UnwindTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.performSegue(withIdentifier: Configuration.Segues.UnwindToMainViewController, sender: nil)
        }
    }

    fileprivate func getDuration(interval: TimeInterval) -> String {
        let connectDuration = Int(interval)
        
        let seconds = connectDuration % 60
        let minutes = (connectDuration / 60) % 60
        let hours = (connectDuration / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
}
