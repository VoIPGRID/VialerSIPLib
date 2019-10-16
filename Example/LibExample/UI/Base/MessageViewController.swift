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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func handle(msg: Message) {
        
    }
}
