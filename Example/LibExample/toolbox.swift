//
//  toolbox.swift
//  LibExample
//
//  Created by Manuel on 17/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//
import Foundation

// MARK: - public tools
func delay(by timeInterval:DispatchTimeInterval, callback:@escaping () ->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval, execute: callback)
}

func checkHandle(_ handle:String) -> Bool {
    return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn:handle))
        && handle != ""
}

func normalise(_ handle:String) -> String {
    return removeNonAlphanumericCharacters(normaliseInternational(trim(handle)))
}

// MARK: - private tools
fileprivate
func trim(_ handle:String) -> String {
    return handle.trimmingCharacters(in: .whitespacesAndNewlines)
}

fileprivate
func removeNonAlphanumericCharacters(_ handle:String) -> String {
    return handle.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
}

fileprivate
func normaliseInternational(_ handle:String) -> String {
    var handle = handle
    if handle.hasPrefix("+") {
        let range = handle.startIndex..<handle.index(after: handle.startIndex)
        handle = handle.replacingCharacters(in: range, with: "00")
    }
    return handle
}
