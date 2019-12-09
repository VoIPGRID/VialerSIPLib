//
//  IPAddressChecker.swift
//  LibExample
//
//  Created by Manuel on 09/12/2019.
//  Copyright © 2019 Harold. All rights reserved.
//

protocol IPAddressChecking {
    func check(ip: String) -> Bool
}

final
class IPAddressChecker: IPAddressChecking {
    func check(ip: String) -> Bool { return ip.isIpAddress() }
}

fileprivate
extension String {
    
    func isIpAddress() -> Bool { return self.isIPv6() || self.isIPv4() }

    private func isIPv4() -> Bool {
        var sin = sockaddr_in()
        return self.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1
    }
    
    private func isIPv6() -> Bool {
        var sin6 = sockaddr_in6()
        return self.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1
    }
}
