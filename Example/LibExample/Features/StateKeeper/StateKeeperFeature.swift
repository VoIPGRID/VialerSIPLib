//
//  StateKeeperFeature.swift
//  LibExample
//
//  Created by Manuel on 01/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

final
class StateKeeperFeature: Feature {
    required init(with rootMessageHandler: MessageHandling, dependencies: Dependencies) {
        self.rootMessageHandler = rootMessageHandler
        self.dependencies = dependencies
    }
    
    private weak var rootMessageHandler: MessageHandling?
    private let dependencies: Dependencies
    private lazy var keepState = KeepState(dependencies: self.dependencies){[weak self] response in self?.handle(response: response)}

    func handle(feature: Message.Feature) {
        if case .settings(.useCase(       .transport(.action(   .didActivate(let mode    )))))  = feature { keepState.handle(request: .setTransportMode(    mode, keepState.state)) }
        if case .settings(.useCase(          .server(.action(.addressChanged(let address )))))  = feature { keepState.handle(request: .setServerAddress( address, keepState.state)) }
        if case .settings(.useCase(        .password(.action(.changePassword(let password)))))  = feature { keepState.handle(request:      .setPassword(password, keepState.state)) }
        if case    .state(.useCase(.loadInitialState                                        ))  = feature { keepState.handle(request:        .loadState                           ) }
        if case    .state(.useCase(           .reset                                        ))  = feature { keepState.handle(request:       .resetState                           ) }

    }
    
    private func handle(response: KeepState.Response) {
        switch response {
        case         .stateChanged(let state)           : rootMessageHandler?.handle(msg: .feature(.state(.useCase(      .stateChanged(state       )))))
        case          .stateLoaded(let state)           : rootMessageHandler?.handle(msg: .feature(.state(.useCase(       .stateLoaded(state       )))))
        case     .failedPersisting(let state, let error): rootMessageHandler?.handle(msg: .feature(.state(.useCase(  .persistingFailed(state, error)))))
        case   .failedLoadingState(           let error): rootMessageHandler?.handle(msg: .feature(.state(.useCase(.stateLoadingFailed(       error)))))
        case        .stateWasReset                      : rootMessageHandler?.handle(msg: .feature(.state(.useCase(  .loadInitialState              ))))
        case  .failedDeletingState(           let error): rootMessageHandler?.handle(msg: .feature(.state(.useCase(   .resettingFailed(       error)))))
        case      .passwordChanged(let state)           : rootMessageHandler?.handle(msg: .feature(.settings(.useCase(.password(.action(.passwordChanged(state.encryptedPassword)))))))
        case .passwordChangeFailed(           let error): rootMessageHandler?.handle(msg: .feature(.settings(.useCase(.password(.action(.passwordChangeFailed(error)))))))
            
        }
    }
}
