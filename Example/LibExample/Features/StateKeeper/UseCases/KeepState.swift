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
        case setPassword(String, AppState)
        case loadState
        case resetState
    }
    
    enum Response {
        case       stateChanged(AppState)
        case        stateLoaded(AppState)
        case   failedPersisting(AppState, Error)
        case failedLoadingState(          Error)
        case stateWasReset
        case failedDeletingState(         Error)
        case passwordChanged(AppState)
        case passwordChangeFailed(Error)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((KeepState.Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())
    private let dependencies: Dependencies
    private lazy var interactor: KeepState.Interactor = Interactor(statePersister: self.dependencies.statePersister)
    
    var state: AppState = AppState(transportMode: .tcp, accountNumber: Keys.SIP.Account, serverAddress: Keys.SIP.Domain, encryptedPassword: Keys.SIP.Password)
    
    func handle(request: KeepState.Request) {
        interactor.state = state
        interactor.handle(request: request) { [weak self] response in self?.handle(response: response) }
    }
    
    private func handle(response: KeepState.Response) {
        switch response {
        case        .stateWasReset                      :            stateWasReset()
        case         .stateChanged(let state           ):             stateChanged(for: state             )
        case          .stateLoaded(let state           ):                   loaded(for: state             )
        case     .failedPersisting(let state, let error):         persistingFailed(for: state, with: error)
        case   .failedLoadingState(           let error): handleFailedLoadingState(            with: error)
        case  .failedDeletingState(           let error):     stateResettingFailed(            with: error)
        case      .passwordChanged(let state           ):          passwordChanged(for: state             )
        case .passwordChangeFailed(let error           ):     passwordChangeFailed(            with: error)
        }
    }
    
    private func stateChanged(for state: AppState) {
        self.state = state
        responseHandler(.stateChanged(state))
    }
    
    private func persistingFailed(for state: AppState, with error: Error) {
        self.state = state
        responseHandler(.failedPersisting(state, error))
    }
    
    private func loaded(for state: AppState) {
        self.state = state  
        responseHandler(.stateLoaded(state))
    }
    
    private func handleFailedLoadingState(with error: Error) {
        responseHandler(.failedLoadingState(error))
    }
    
    private func stateWasReset() {
        responseHandler(.stateWasReset)
    }
    
    private func stateResettingFailed(with error: Error) {
        responseHandler(.failedDeletingState(error))
    }
    
    private func passwordChanged(for state: AppState) {
        self.state = state
        responseHandler(.passwordChanged(state))
    }
    
    private func passwordChangeFailed(with error: Error) {
        responseHandler(.passwordChangeFailed(error))
    }
}

extension KeepState {
    private class Interactor {
        init(statePersister: StatePersisting) {
            self.statePersister = statePersister
        }
        
        func handle(request: KeepState.Request, response: @escaping ((KeepState.Response) -> ())) {
            switch request {
            case        .resetState                                      :     reset(response: response)
            case         .loadState                                      : loadState(response: response)
            case   .setAccounNumber(let accountNumber, let previousState):       set(accountNumber: accountNumber, previousState: previousState, response:response)
            case  .setTransportMode(         let mode, let previousState):       set(         mode: mode,          previousState: previousState, response:response)
            case  .setServerAddress(      let address, let previousState):       set(serverAddress: address,       previousState: previousState, response: response)
            case       .setPassword(     let password, let previousState):       set(     password: password,      previousState: previousState, response: response)
            }
        }
        
        private let statePersister: StatePersisting
        fileprivate var state: AppState!
        
        private func set(password:String, previousState: AppState, response: ((KeepState.Response) -> ())) {
            let s = AppState(
                transportMode: previousState.transportMode,
                accountNumber: previousState.accountNumber,
                serverAddress: previousState.serverAddress,
                encryptedPassword: password )
            do {
                try statePersister.persist(state: s)
                response(.passwordChanged(s))
            } catch let error {
                response(.passwordChangeFailed(error))
            }
            
        }
        
        private func set(mode: TransportMode, previousState: AppState, response: ((KeepState.Response) -> ())) {
            let s = AppState(
                transportMode: mode,
                accountNumber: previousState.accountNumber,
                serverAddress: previousState.serverAddress,
                encryptedPassword: previousState.encryptedPassword )
            do {
                try statePersister.persist(state: s)
                response(.stateChanged(s))
            } catch let error {
                response(.failedPersisting(s, error))
            }
        }
        
        private func set(serverAddress:String, previousState: AppState, response: ((KeepState.Response) -> ())) {
            let s = AppState(
                transportMode: previousState.transportMode,
                accountNumber: previousState.accountNumber,
                serverAddress: serverAddress,
                encryptedPassword: previousState.encryptedPassword )
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
        
        fileprivate func set(accountNumber: String ,previousState: AppState, response: ((KeepState.Response) -> ())) {
            let s = AppState(
                transportMode: previousState.transportMode,
                accountNumber: accountNumber,
                serverAddress: previousState.serverAddress,
                encryptedPassword: previousState.encryptedPassword )
            do {
                try statePersister.persist(state: s)
                response(.stateChanged(s))
            } catch let error {
                response(.failedPersisting(s, error))
            }
        }
        
        func reset(response: ((KeepState.Response) -> ())) {
            do {
                try statePersister.deleteState()
                response(.stateWasReset)
            } catch let error {
                response(.failedDeletingState(error))
            }
        }
    }
}
