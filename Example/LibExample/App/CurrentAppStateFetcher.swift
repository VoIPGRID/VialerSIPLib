//
//  CurrentAppStateFetcher.swift
//  LibExample
//
//  Created by Manuel on 06/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

protocol CurrentAppStateFetching: MessageSubscriber {
    var appState: AppState? { get }
}

class CurrentAppStateFetcher: CurrentAppStateFetching {
    var appState: AppState?
    
    func handle(msg: Message) {
        if case .feature(.state(.useCase( .stateLoaded(let state)))) = msg { appState = state }
        if case .feature(.state(.useCase(.stateChanged(let state)))) = msg { appState = state }
        
    }
}
