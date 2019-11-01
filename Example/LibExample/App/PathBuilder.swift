//
//  PathBuilder.swift
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
