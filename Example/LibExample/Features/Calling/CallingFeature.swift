//
//  CallingFeature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class CallingFeature: Feature {
    
    required init(with rootMessageHandler: MessageHandling) {
        self.rootMessageHandler = rootMessageHandler
    }
    
    private weak var rootMessageHandler:MessageHandling?
    
    // useCases
    private lazy var startCall = StartCall(){ [weak self] response in self?.handle(response: response) }
    private lazy var endCall   = EndCall()  { [weak self] response in self?.handle(response: response) }
    
    func handle(feature: Message.Feature) {
        if case .calling(.useCase(let useCase)) = feature {
            handle(useCase: useCase)
        }
    }
    
    private func handle(useCase: Message.Feature.Calling.UseCase) {
        switch useCase {
        case .call(.action(.start)):
            startCall.handle(request: .startCall)
        case .call(.action(.stop)):
            endCall.handle(request: .stop)
        default:
            break
        }
    }
    
    private func handle(response: StartCall.Response) {
        switch response {
        case .callDidStart:
            rootMessageHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.callDidStart))))))
        }
    }

    private func handle(response: EndCall.Response) {
        switch response {
        case .callDidStop:
            rootMessageHandler?.handle(msg: .feature(.calling(.useCase(.call(.action(.callDidStop))))))
        }
    }
}
