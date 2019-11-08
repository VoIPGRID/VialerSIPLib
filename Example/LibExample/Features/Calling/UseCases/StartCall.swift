//
//  StartCall.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

// MARK: - UseCase
final
class StartCall: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    required init(dependencies:Dependencies, responseHandler: @escaping ((Response) -> ())) {
        self.responseHandler = responseHandler
        self.dependencies = dependencies
    }
    
    private let responseHandler: ((Response) -> ())
    private lazy var interactor = StartCall.Interactor(callStarter: dependencies.callStarter) { self.responseHandler($0) }
    private let dependencies: Dependencies

    func handle(request: Request) {
        interactor.handle(request: request)
    }
}

// MARK: - Request & Response
extension StartCall {
    enum Request {
        case startCall(Call, AppState)
    }
    
    enum Response {
        case dialing(Call)
        case callDidStart(Call)
        case failedStarting(Call)
    }
}

// MARK: - Interactor
extension StartCall {
    private class Interactor {
        init(callStarter:CallStarting, response: @escaping (StartCall.Response) -> Void) {
            self.response = response
            var callStarter = callStarter
            callStarter.callback = { [weak self] success, call in
                self?.handle(result: (success: success, call: call))
            }
            self.callStarter = callStarter
        }
        
        private let response: (StartCall.Response) -> Void
        private var callStarter: CallStarting?
        
        func handle(request:StartCall.Request) {
            switch request {
            case .startCall(let call, let appState):
                response(.dialing(call))
                callStarter?.appState = appState
                callStarter?.start(call: call)
            }
        }
        
        private func handle(result: (success:Bool, call: Call)) {
            switch result.success {
            case  true: self.response(  .callDidStart(transform(result.call, with: .started)))
            case false: self.response(.failedStarting(transform(result.call, with:  .failed)))
            }
        }
    }
}

// MARK: - Gateways
protocol CallStarting {
    var callback: ((Bool, Call) -> Void)? { get set }
    var appState: AppState? { get set }

    func start(call:Call)
}
