//
//  StateKeeperFeature.swift
//  LibExample
//
//  Created by Manuel on 01/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation


protocol PathBuilding {
    func dictionaryInDocuments(named name:String, fileManger: FileManager) throws -> URL
}

struct PathBuilder: PathBuilding {
    func dictionaryInDocuments(named name:String, fileManger: FileManager) throws -> URL {
        let dir = fileManger.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name, isDirectory: true)
        try fileManger.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
     
        return dir
    }
}



protocol StatePersisting {
    func persist(state: AppState) throws
}


struct StateDiskPersister: StatePersisting {
    
    init(pathBuilder: PathBuilding, fileManager: FileManager) {
        self.pathBuilder = pathBuilder
        self.fileManager = fileManager
    }
    
    private let fileManager: FileManager
    private let pathBuilder: PathBuilding
    
    func persist(state: AppState) throws {
        let dir =  try pathBuilder.dictionaryInDocuments(named: "state", fileManger: fileManager)
        let data = try PropertyListSerialization.data(fromPropertyList: state.dictionary, format: .xml, options: 0)
        try data.write(to: dir.appendingPathComponent("state.xml"))
    }
}


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
        if case .settings(.useCase(.transport(.action(.didActivate(let mode))))) = feature { keepState.handle(request: .setTransportMode(mode)) }
    }
    
    private func handle(response: KeepState.Response) {
        switch response {
        case     .stateChanged(let state)           : rootMessageHandler?.handle(msg: .feature(.state(.useCase(.stateChanged    (state)))))
        case .failedPersisting(let state, let error): rootMessageHandler?.handle(msg: .feature(.state(.useCase(.persistingFailed(state, error)))))
        }
    }
}
