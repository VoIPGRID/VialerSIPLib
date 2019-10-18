//
//  File.swift
//  LibExample
//
//  Created by Manuel on 18/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation


struct CallStarter: CallStarting {
    var callback: ((Bool, Call) -> Void)?
    
    
    init() {}
    
    func start(call: Call) {
        checkHandle(call.handle)
            ? delay(by: .milliseconds(.random(in: 100..<1500))) { self.callback?(true,  call)}
            : delay(by: .milliseconds(.random(in: 100..<0750))) { self.callback?(false, call)}
    }
}
