//
//  StartCall.swift
//  LibExample
//
//  Created by Manuel on 10/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//
import Foundation

final
class StartCall: UseCase {
    typealias RequestType = Request
    typealias ResponseType = Response
    
    enum Request {
        case startCall(Call)
    }
    
    enum Response {
        case dialing(Call)
        case callDidStart(Call)
        case failedStarting(Call)
    }
    
    convenience init(responseHandler: @escaping ((Response) -> ())) {
        self.init(handleChecker: checkHandle , responseHandler: responseHandler)
    }
    
    required init(handleChecker: @escaping (String) -> Bool, responseHandler: @escaping ((Response) -> ())) {
        self.handleChecker = handleChecker
        self.responseHandler = responseHandler
    }
    
    private let responseHandler: ((Response) -> ())
    private let handleChecker: (String) -> Bool
    
    func handle(request: Request) {
        switch request {
        case .startCall(let call):
            if(handleChecker(normalise(call.handle))) {
                responseHandler(.dialing(call))
                dispatch(in: .milliseconds(.random(in: 250..<750))) { self.responseHandler(.callDidStart(  transform(call, with: .started))) }
            } else {
                dispatch(in: .milliseconds(.random(in: 150..<500))) { self.responseHandler(.failedStarting(transform(call, with:  .failed))) }
            }
        }
    }
}


//MARK: -
fileprivate func dispatch(in timeInterval:DispatchTimeInterval, callback:@escaping () ->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval, execute: callback)
}

fileprivate
func checkHandle(_ handle:String) -> Bool {
    return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn:handle))
        && handle != ""
}

fileprivate
func normalise(_ handle:String) -> String {
    return removeNonAlphanumericCharacters(normaliseInternational(trim(handle)))
}

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
