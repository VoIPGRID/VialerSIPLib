//
//  StatePersister.swift
//  LibExample
//
//  Created by Manuel on 01/11/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation

protocol StatePersisting {
    func persist(state: AppState) throws
    func loadState() throws -> AppState?
}

struct StateDiskPersister: StatePersisting {
    
    private let dirName = "state"
    private let fileName = "state.xml"
    
    init(pathBuilder: PathBuilding, fileManager: FileManager) {
        self.pathBuilder = pathBuilder
        self.fileManager = fileManager
    }
    
    private let fileManager: FileManager
    private let pathBuilder: PathBuilding
    
    func persist(state: AppState) throws {
        let dir =  try pathBuilder.dictionaryInDocuments(named: dirName, fileManger: fileManager)
        let data = try PropertyListSerialization.data(fromPropertyList: state.dictionary, format: .xml, options: 0)
        try data.write(to: dir.appendingPathComponent(fileName))
    }
    
    func loadState() throws -> AppState? {
        let dir =  try pathBuilder.dictionaryInDocuments(named: dirName, fileManger: fileManager)
        if let data = fileManager.contents(atPath: dir.appendingPathComponent(fileName).path) {
            if let dict = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : String] {
                if let modeString = dict["transportMode"], let accountNumber = dict["accountNumber"] {
                    if let mode = TransportMode(rawValue: modeString) {
                        return AppState(transportMode: mode, accountNumber: accountNumber)
                    }
                }
            }
        } else {
            return AppState(transportMode: .udp, accountNumber: Keys.SIP.Account)
        }
        return nil
    }
}
