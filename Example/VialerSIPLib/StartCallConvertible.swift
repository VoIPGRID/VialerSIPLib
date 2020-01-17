/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information

	Abstract:
	Protocol defining a type from which a call may be started.

        Copied from Speakerbox example app.
 */

protocol StartCallConvertible {
    var startCallHandle: String? { get }
    var video: Bool? { get }
}

extension StartCallConvertible {
    var video: Bool? {
        return nil
    }
}
