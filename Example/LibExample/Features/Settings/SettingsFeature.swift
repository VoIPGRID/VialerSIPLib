//
//  SettingsFeature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

class SettingsFeature: Feature {
    
    required init(with rootMessageHandler: MessageHandling, dependencies: Dependencies) {
        self.rootMessageHandler = rootMessageHandler
        self.dependencies = dependencies

    }
    
    private weak var rootMessageHandler: MessageHandling?
    private let dependencies: Dependencies

    private lazy var switchTransportMode = SwitchTransportMode(dependencies: self.dependencies) { [weak self] response in self?.handle(response: response) }
    private lazy var        changeServer =        ChangeServer(dependencies: self.dependencies) { [weak self] response in self?.handle(response: response) }

    func handle(feature: Message.Feature) {
        if case .settings(.useCase(let useCase)) = feature {
            handle(useCase: useCase)
        }
    }
    
    private func handle(useCase: Message.Feature.Settings.UseCase) {
        if case .transport(.action(     .activate(let    mode))) = useCase { switchTransportMode.handle(request: .setMode(mode)         ) }
        if case    .server(.action(.changeAddress(let address))) = useCase {        changeServer.handle(request: .changeAddress(address)) }
    }
    
    private func handle(response: SwitchTransportMode.Response) {
        switch response {
        case .modeWasActivated(let mode):
            rootMessageHandler?.handle(msg: .feature(.settings(.useCase(.transport(.action(.didActivate(mode)))))))
        }
    }
    
    private func handle(response: ChangeServer.Response) {
        switch response {
        case .addressChanged(let address):
            rootMessageHandler?.handle(msg: .feature(.settings(.useCase(.server(.action(.addressChanged(address)))))))
        }
    }
}
