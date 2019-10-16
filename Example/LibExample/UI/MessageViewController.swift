//
//  MessageViewController.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController, MessageHandling, ResponseHandling {
    
    var responseHandler: MessageHandling?
    
    @IBOutlet weak var phoneNumberField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func handle(msg: Message) {
        switch msg {
        case .feature(.calling(.useCase(.call(.action(.callDidStart(_)))))):
            phoneNumberField.backgroundColor = .green
        case .feature(.calling(.useCase(.call(.action(.failedToStartCall(_)))))):
            phoneNumberField.backgroundColor = .orange
            
        default:
            break
        }
    }
    
    @IBAction func call(_ sender: Any) {
            responseHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.start(phoneNumberField.text ?? "")))))))
    }
}
