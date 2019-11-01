//
//  AppState.swift
//  LibExample
//
//  Created by Manuel on 01/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

struct AppState {
    let transportMode: TransportMode
    
    var dictionary: [String : String] {
        return ["transportMode": "\(transportMode)"]
    }
}
