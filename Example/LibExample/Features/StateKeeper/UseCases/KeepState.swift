//
//  KeepState.swift
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

class KeepState: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case setTransportMode(TransportMode)
        case loadState
    }
    
    enum Response {
        case stateChanged(AppState)
        case stateLoaded(AppState)
        case failedPersisting(AppState, Error)
        case failedLoadingState(Error)
    }
    
    required init(dependencies: Dependencies, responseHandler: @escaping ((KeepState.Response) -> ())) {
        self.dependencies = dependencies
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())
    private let dependencies: Dependencies
    private lazy var interactor: KeepState.Interactor = Interactor(statePersister: self.dependencies.statePersister)
    
    var state: AppState = AppState(transportMode: .tcp)

    func handle(request: KeepState.Request) {
        interactor.handle(request: request) { [weak self] response in self?.handle(response: response) }
    }
    
    private func handle(response: KeepState.Response) {
        if case     .stateChanged(let state)            = response {          handleChanged(state: state)             }
        if case .failedPersisting(let state, let error) = response { handleFailedPersisting(state: state, with: error)}
        
        switch response {
        case       .stateChanged(let state)           : handleChanged(state: state)
        case        .stateLoaded(let state)           : handleStateLoaded(state: state)
        case   .failedPersisting(let state, let error): handleFailedPersisting(state: state, with: error)
        case .failedLoadingState(           let error): handleFailedLoadingState(error: error)
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
    
    private func handleFailedLoadingState(error: Error) {
        responseHandler(.failedLoadingState(error))
    }
}

extension KeepState {
    private class Interactor {
        
        init(statePersister: StatePersisting) {
            self.statePersister = statePersister
        }
        
        let statePersister: StatePersisting
        
        func handle(request: KeepState.Request, response: @escaping ((KeepState.Response) -> ())) {
            switch request {
            case .setTransportMode(let mode):
                let s = AppState(transportMode: mode)
                do {
                    try statePersister.persist(state: s)
                    response(.stateChanged(s))
                } catch let error {
                    response(.failedPersisting(s, error))
                }
            case .loadState:
                do {
                    if let state = try statePersister.loadState() {
                        response(.stateLoaded(state))
                    }
                } catch let error {
                    response(.failedLoadingState(error))
                }
            }
        }
    }
}

