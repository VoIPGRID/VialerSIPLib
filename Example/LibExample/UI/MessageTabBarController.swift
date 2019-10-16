//
//  MessageTabBarController.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

class MessageTabBarController: UITabBarController, MessageHandling, ResponseHandling, MessageSubscriber {
    
    var responseHandler: MessageHandling? {
        didSet {
            viewControllers?.forEach {
                if var handler = $0 as? ResponseHandling  {
                    handler.responseHandler = responseHandler
                }
            }
        }
    }
    
    func handle(msg: Message) {
        viewControllers?.compactMap { $0 as? MessageHandling}.forEach { $0.handle(msg: msg)}
    }
    
}
