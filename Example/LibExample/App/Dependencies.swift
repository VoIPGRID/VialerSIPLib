//
//  Dependencies.swift
//  LibExample
//
//  Created by Manuel on 18/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

struct Dependencies {
    var currentAppStateFetcher: CurrentAppStateFetching
    var callStarter: CallStarting
    var statePersister: StatePersisting
    var ipAddressChecker: IPAddressChecking
    var featureToggler: FeatureToggling
}
