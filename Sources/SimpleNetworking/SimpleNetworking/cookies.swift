//
//  cookies.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

#if canImport(FoundationNetworking)
// Support network calls in Linux.
import FoundationNetworking
#endif

extension SimpleNetworking {
    /// Create and add a cookie to the storage
    /// - Parameters:
    ///   - domain: cookie domain
    ///   - path: cookie path
    ///   - name: cookie name
    ///   - value: cookie value
    @discardableResult public func cookie(domain: String, path: String, name: String, value: String) -> Bool {
        if let cookie = HTTPCookie(properties: [
            .domain: domain,
            .path: path,
            .name: name,
            .value: value
        ]) {
            cookies?.append(cookie)
            return true
        } else {
            return false
        }
    }

    /// Remove cookie from storage
    /// - Parameters:
    ///   - deleteCookieWithDomain: cookie domain
    ///   - path: cookie path
    ///   - name: cookie name
    ///   - value: cookie value
    public func cookie(deleteCookieWithDomain: String?, path: String?, name: String?, value: String?) {
        var newCookieStorage: [HTTPCookie] = []

        guard let unwrapped = cookies else {
            return
        }

        for cookie in unwrapped where ![
        cookie.domain == deleteCookieWithDomain,
        cookie.path == path,
        cookie.name == name,
        cookie.value == value
        ].contains(true) {
            newCookieStorage.append(cookie)
        }

        cookies = newCookieStorage
    }

    /// Reset cookie storage
    /// - Parameter reset: reset
    public func cookie(reset: Bool) {
        if reset {
            cookies?.removeAll()

            assert((cookies ?? []).isEmpty, "Failed to reset cookie storage.")
        }
    }
}
