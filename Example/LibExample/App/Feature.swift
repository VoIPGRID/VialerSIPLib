//
//  Feature.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

protocol Feature {
    init(with rootMessageHandler:MessageHandling)
    func handle(feature: Message.Feature)
}
