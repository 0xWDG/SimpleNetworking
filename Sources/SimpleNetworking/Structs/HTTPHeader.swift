//
//  HTTPMethod.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 27/12/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

extension SimpleNetworking {
    /// HTTP Header
    public struct HTTPHeader: Identifiable, Hashable, Equatable {
        /// Identifier
        public let id = UUID()

        /// HTTP Header name
        public let name: String

        /// HTTP Header value
        public let value: String

        /// HTTP Header
        /// - Parameter name: HTTP Header name
        /// - Parameter value: HTTP Header value
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
}
