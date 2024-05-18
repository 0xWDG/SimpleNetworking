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
    public struct NetworkingError: Error {
        /// Error message
        let message: String

        /// Initialize networking error
        /// - Parameter message: error message to show
        init(message: String) {
            self.message = message
        }

        /// The error message
        public var localizedDescription: String {
            return message
        }

        /// The error code
        public var code: Int {
            return (self as NSError).code
        }
    }
}
