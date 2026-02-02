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

extension SimpleNetworking {
    /// Networking error (generator)
    public struct NetworkingError: Error, LocalizedError, Equatable {
        /// Error message
        let message: String

        /// Initialize networking error
        /// - Parameter message: error message to show
        init(message: String) {
            self.message = message
        }

        /// The error description for LocalizedError protocol
        public var errorDescription: String? {
            return message
        }

        /// The error code
        public var code: Int {
            return (self as NSError).code
        }

        /// Equatable conformance
        public static func == (lhs: NetworkingError, rhs: NetworkingError) -> Bool {
            return lhs.message == rhs.message
        }
    }
}
