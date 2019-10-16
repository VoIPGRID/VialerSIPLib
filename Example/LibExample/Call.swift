//
//  File.swift
//  LibExample
//
//  Created by Manuel on 14/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation

struct Call {
    
    init(handle: String) {
        self.uuid = UUID()
        self.handle = handle
        self.state = .uninitialized
    }
    
    fileprivate init(handle: String, uuid: UUID, state: State) {
        self.uuid = uuid
        self.state = state
        self.handle = handle
    }
    
    let uuid: UUID
    let handle: String
    let state: State
    
    enum State {
        case uninitialized
        case initialized
        case started
        case ended
        case failed
    }
}

func transform(_ call: Call, with newState:Call.State) -> Call {
    return Call(handle: call.handle, uuid: call.uuid, state: newState)
}

extension Call: Equatable {
    static func == (
        lhs: Call,
        rhs: Call
    ) -> Bool
    {
        return lhs.uuid == rhs.uuid && lhs.state == rhs.state
    }
}
