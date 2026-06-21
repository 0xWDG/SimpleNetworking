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
    internal func cookieSnapshot() -> [HTTPCookie] {
        stateLock.lock()
        defer { stateLock.unlock() }

        return cookies ?? []
    }

    internal func addStoredCookies(to request: inout URLRequest) {
        stateLock.lock()
        let storedCookies = cookies ?? []
        stateLock.unlock()

        guard !storedCookies.isEmpty,
              let cookieHeader = HTTPCookie.requestHeaderFields(with: storedCookies)["Cookie"] else {
            return
        }

        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
    }

    internal func saveCookies(from response: URLResponse?) {
        guard let httpResponse = response as? HTTPURLResponse,
              let url = httpResponse.url else {
            return
        }

        let headerFields = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, header in
            guard let key = header.key as? String else {
                return
            }

            result[key] = "\(header.value)"
        }
        let responseCookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)

        guard !responseCookies.isEmpty else {
            return
        }

        stateLock.lock()
        for cookie in responseCookies {
            cookies?.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
            cookies?.append(cookie)
        }
        stateLock.unlock()
    }

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
            stateLock.lock()
            cookies?.append(cookie)
            stateLock.unlock()
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

        stateLock.lock()
        defer { stateLock.unlock() }

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
            stateLock.lock()
            defer { stateLock.unlock() }

            cookies?.removeAll()

            assert((cookies ?? []).isEmpty, "Failed to reset cookie storage.")
        }
    }
}
