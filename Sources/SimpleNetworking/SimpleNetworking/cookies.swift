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
        withStateLock { cookieStorage ?? [] }
    }

    internal func addStoredCookies(to request: inout URLRequest) {
        let storedCookies = withStateLock { cookieStorage ?? [] }

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

        withStateLock {
            for cookie in responseCookies {
                cookieStorage?.removeAll { $0.name == cookie.name }
                cookieStorage?.append(cookie)
            }
        }
    }

    /// Create or replace the cookie stored under `name`.
    ///
    /// The storage keeps one cookie per name. Adding another cookie with the same name replaces its value,
    /// domain, and path so stale credentials are not sent alongside the replacement.
    /// - Parameters:
    ///   - domain: Domain to which the cookie applies.
    ///   - path: URL path to which the cookie applies.
    ///   - name: Stable key used to find and replace an existing cookie.
    ///   - value: New cookie value.
    @discardableResult public func cookie(domain: String, path: String, name: String, value: String) -> Bool {
        if let cookie = HTTPCookie(properties: [
            .domain: domain,
            .path: path,
            .name: name,
            .value: value
        ]) {
            withStateLock {
                cookieStorage?.removeAll { $0.name == cookie.name }
                cookieStorage?.append(cookie)
            }
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
        withStateLock {
            guard let unwrapped = cookieStorage else {
                return
            }

            cookieStorage = unwrapped.filter { cookie in
                ![
                    cookie.domain == deleteCookieWithDomain,
                    cookie.path == path,
                    cookie.name == name,
                    cookie.value == value
                ].contains(true)
            }
        }
    }

    /// Reset cookie storage
    /// - Parameter reset: reset
    public func cookie(reset: Bool) {
        if reset {
            withStateLock {
                cookieStorage?.removeAll()
                assert((cookieStorage ?? []).isEmpty, "Failed to reset cookie storage.")
            }
        }
    }
}
