//
//  Request.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 25/09/2026.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension SimpleNetworking {
    /// An immutable description of one HTTP request.
    public struct Request {
        /// The endpoint path, relative to the client's configured server URL.
        public let path: String
        /// The standard HTTP method, when one is used.
        public let method: HTTPMethod?
        /// A custom HTTP method, normalized to uppercase.
        public let customMethod: String?
        /// The raw body used with a custom method.
        public let body: Data?
        /// Query items appended to the endpoint URL.
        public let query: [URLQueryItem]
        /// Headers that override or extend the client's defaults.
        public let headers: [HTTPHeader]
        /// An optional request timeout, in seconds.
        public let timeout: TimeInterval?
        /// An optional URL loading cache policy.
        public let cachePolicy: URLRequest.CachePolicy?
        /// The body encoding used with standard methods that carry data.
        public let encoding: POSTEncoding

        /// Create a request using SimpleNetworking's standard HTTP methods.
        public init(
            path: String,
            method: HTTPMethod,
            query: [String: String] = [:],
            headers: [HTTPHeader] = [],
            timeout: TimeInterval? = nil,
            cachePolicy: URLRequest.CachePolicy? = nil,
            encoding: POSTEncoding = .auto
        ) {
            self.path = path
            self.method = method
            customMethod = nil
            body = nil
            self.query = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            self.headers = headers
            self.timeout = timeout
            self.cachePolicy = cachePolicy
            self.encoding = encoding
        }

        /// Create a request using a custom HTTP method and a raw request body.
        public init(
            path: String,
            method: String,
            body: Data? = nil,
            query: [URLQueryItem] = [],
            headers: [HTTPHeader] = [],
            timeout: TimeInterval? = nil,
            cachePolicy: URLRequest.CachePolicy? = nil
        ) {
            self.path = path
            self.method = nil
            customMethod = method.uppercased()
            self.body = body
            self.query = query
            self.headers = headers
            self.timeout = timeout
            self.cachePolicy = cachePolicy
            encoding = .plain
        }
    }
}
