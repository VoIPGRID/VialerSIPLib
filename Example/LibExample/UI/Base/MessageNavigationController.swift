//
//  MessageNavigationController.swift
//  LibExample
//
//  Created by Manuel on 16/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import UIKit

class MessageNavigationController: UINavigationController, MessageHandling, ResponseHandling {
    
    var responseHandler: MessageHandling? {
        didSet { viewControllers.compactMap { $0 as? ResponseHandling }.forEach { var x = $0; x.responseHandler = responseHandler } }
    }
    
    func handle(msg: Message) {
        viewControllers.compactMap { $0 as? MessageHandling}.forEach { $0.handle(msg: msg)}
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if var vc = viewController as? ResponseHandling {
            vc.responseHandler = responseHandler
        }
        super.pushViewController(viewController, animated: animated)
    }
}
