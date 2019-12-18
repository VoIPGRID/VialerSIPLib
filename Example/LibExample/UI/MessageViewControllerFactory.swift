//
//  MessageViewControllerFactory.swift
//  LibExample
//
//  Created by Manuel on 18/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

import Foundation

enum FactoryKind {
    case calling
    case settings
    case featureFlagSettings
}

protocol MessageViewControllerFactoring {
    func make() -> MessageViewController
}

final class MessageViewControllerFactory: MessageViewControllerFactoring {
    init(kind: FactoryKind) {
        self.kind = kind
    }
    
    private let kind: FactoryKind
    
    func make() -> MessageViewController {
        switch kind {
        case             .calling: return CallingViewController(nibName: nil, bundle: nil)
        case            .settings: return SettingsViewController(nibName: nil, bundle: nil)
        case .featureFlagSettings: return FeatureFlagSettingsViewController(nibName: nil, bundle: nil)
        }
    }
}
