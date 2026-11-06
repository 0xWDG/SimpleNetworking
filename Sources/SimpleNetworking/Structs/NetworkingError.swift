//
//  NetworkingError.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

/// Identifies the stage at which a networking operation failed.
public enum NetworkingErrorKind: String, Sendable {
    case invalidURL
    case noSession
    case transport
    case httpStatus
    case decoding
    case cancelled
    case custom
}

extension SimpleNetworking {
    /// A structured error produced while preparing, executing, or decoding a request.
    public struct NetworkingError: Error, LocalizedError, @unchecked Sendable, Equatable {
        // Preserve the established public spelling `NetworkingError.Kind`.
        // swiftlint:disable:next nesting
        public typealias Kind = NetworkingErrorKind

        public let kind: NetworkingErrorKind
        public let message: String
        public let statusCode: Int?
        public let responseHeaders: [HTTPHeader]
        public let bodySnippet: String?
        public let underlyingError: Error?

        /// Create a custom networking error.
        public init(message: String) {
            self.init(kind: .custom, message: message)
        }

        public init(
            kind: NetworkingErrorKind,
            message: String,
            statusCode: Int? = nil,
            responseHeaders: [HTTPHeader] = [],
            bodySnippet: String? = nil,
            underlyingError: Error? = nil
        ) {
            self.kind = kind
            self.message = message
            self.statusCode = statusCode
            self.responseHeaders = responseHeaders
            self.bodySnippet = bodySnippet
            self.underlyingError = underlyingError
        }

        public static func invalidURL(_ endpoint: String) -> Self {
            .init(kind: .invalidURL, message: "Invalid URL: \(endpoint)")
        }

        public static let noSession = Self(kind: .noSession, message: "No URLSession available")

        public static func transport(_ error: Error) -> Self {
            let kind: NetworkingErrorKind = (error as? URLError)?.code == .cancelled ? .cancelled : .transport
            return .init(kind: kind, message: error.localizedDescription, underlyingError: error)
        }

        public static func httpStatus(response: NetworkResponse) -> Self {
            .init(
                kind: .httpStatus,
                message: "HTTP \(response.statuscode ?? 0)",
                statusCode: response.statuscode,
                responseHeaders: response.headers,
                bodySnippet: response.bodySnippet
            )
        }

        public static func decoding(_ error: Error, response: NetworkResponse) -> Self {
            .init(
                kind: .decoding,
                message: "Failed to decode response: \(error.localizedDescription)",
                statusCode: response.statuscode,
                responseHeaders: response.headers,
                bodySnippet: response.bodySnippet,
                underlyingError: error
            )
        }

        public var errorDescription: String? { message }

        public var code: Int { (self as NSError).code }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.kind == rhs.kind &&
                lhs.message == rhs.message &&
                lhs.statusCode == rhs.statusCode &&
                lhs.responseHeaders == rhs.responseHeaders &&
                lhs.bodySnippet == rhs.bodySnippet &&
                lhs.underlyingError?.localizedDescription == rhs.underlyingError?.localizedDescription
        }
    }
}
