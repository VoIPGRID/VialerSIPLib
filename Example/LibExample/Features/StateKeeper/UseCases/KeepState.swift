//
//  KeepState.swift
//  LibExample
//
//  Created by Manuel on 01/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class KeepState: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case setTransportMode(TransportMode, AppState)
        case setServerAddress(String, AppState)
        case setAccounNumber(String, AppState)
        case loadState
        case fetchCurrentState
    }
    
    enum Response {
        case       stateChanged(AppState)
        case        stateLoaded(AppState)
        case            fetched(AppState)
        case   failedPersisting(AppState, Error)
        case failedLoadingState(          Error)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((KeepState.Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())
    private let dependencies: Dependencies
    private lazy var interactor: KeepState.Interactor = Interactor(statePersister: self.dependencies.statePersister)
    
    var state: AppState = AppState(transportMode: .tcp, accountNumber: Keys.SIP.Account, serverAddress: Keys.SIP.Domain)

    func handle(request: KeepState.Request) {
        interactor.state = state
        interactor.handle(request: request) { [weak self] response in self?.handle(response: response) }
    }
    
    private func handle(response: KeepState.Response) {
        switch response {
        case       .stateChanged(let state)           : handleChanged(state: state)
        case        .stateLoaded(let state)           : handleStateLoaded(state: state)
        case   .failedPersisting(let state, let error): handleFailedPersisting(state: state, with: error)
        case .failedLoadingState(           let error): handleFailedLoadingState(error: error)
        case            .fetched(let state           ): handleFetched(state: state)
            
        }
    }
    
    private func handleChanged(state: AppState) {
        self.state = state
        responseHandler(.stateChanged(state))
    }
    
    private func handleFailedPersisting(state: AppState, with error: Error) {
        self.state = state
        responseHandler(.failedPersisting(state, error))
    }
    
    private func handleStateLoaded(state: AppState) {
        self.state = state  
        responseHandler(.stateLoaded(state))
    }
    
    private func handleFetched(state: AppState) {
        self.state = state
        responseHandler(.fetched(state))
    }
    
    private func handleFailedLoadingState(error: Error) {
        responseHandler(.failedLoadingState(error))
    }
}

extension KeepState {
    fileprivate class Interactor {
        init(statePersister: StatePersisting) {
            self.statePersister = statePersister
        }
        
        func handle(request: KeepState.Request, response: @escaping ((KeepState.Response) -> ())) {
            switch request {
            case         .loadState                                      : loadState(response: response)
            case .fetchCurrentState                                      :  response(.fetched(state))
            case   .setAccounNumber(let accountNumber, let previousState):   persist(previousState: previousState, accountNumber:accountNumber, response:response)
            case  .setTransportMode(         let mode, let previousState):       set(mode:mode, previousState:previousState,response:response)
            case  .setServerAddress(      let address, let previousState):       set(serverAddress: address, previousState: previousState, response: response)
            }
        }
        
        private let statePersister: StatePersisting
        fileprivate var state: AppState!
    }
}

extension KeepState.Interactor {
    private func set(mode: TransportMode, previousState: AppState, response: ((KeepState.Response) -> ())) {
        let s = AppState(transportMode: mode, accountNumber: previousState.accountNumber, serverAddress: previousState.serverAddress)
        do {
            try statePersister.persist(state: s)
            response(.stateChanged(s))
        } catch let error {
            response(.failedPersisting(s, error))
        }
    }
    
    private func set(serverAddress:String, previousState: AppState, response: ((KeepState.Response) -> ())) {
        let s = AppState(transportMode: previousState.transportMode, accountNumber: previousState.accountNumber, serverAddress: serverAddress)
        do {
            try statePersister.persist(state: s)
            response(.stateChanged(s))
        } catch let error {
            response(.failedPersisting(s, error))
        }
    }
    
    fileprivate func loadState(response: ((KeepState.Response) -> ())) {
        do {
            if let state = try statePersister.loadState() {
                response(.stateLoaded(state))
            }
        } catch let error {
            response(.failedLoadingState(error))
        }
    }
    
    fileprivate func persist(previousState: AppState, accountNumber: String, response: ((KeepState.Response) -> ())) {
        let s = AppState(transportMode: previousState.transportMode, accountNumber: accountNumber, serverAddress: previousState.serverAddress)
        do {
            try statePersister.persist(state: s)
            response(.stateChanged(s))
        } catch let error {
            response(.failedPersisting(s, error))
        }
    }
}
