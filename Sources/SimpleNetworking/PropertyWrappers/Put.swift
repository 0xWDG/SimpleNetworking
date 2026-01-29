//
//  Put.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 28/01/2026.
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
    /// Property wrapper for PUT requests
    ///
    /// Usage:
    /// ```swift
    /// @Put("/users/123")
    /// var updateUser: NetworkResponse?
    ///
    /// // Execute the request
    /// let response = await $updateUser.execute(["key": "value"])
    /// ```
    @propertyWrapper
    public struct Put {
        /// Internal storage class to avoid mutation issues
        private class Storage {
            // swiftlint:disable:previous nesting
            var wrappedValue: NetworkResponse?
            init(_ value: NetworkResponse?) {
                self.wrappedValue = value
            }
        }

        /// The URL path for the PUT request
        public let path: String

        /// The networking instance to use
        public var networking: SimpleNetworking = .shared

        /// Storage for the wrapped value
        private let storage: Storage

        /// The wrapped value
        public var wrappedValue: NetworkResponse? {
            get { storage.wrappedValue }
            nonmutating set { storage.wrappedValue = newValue }
        }

        /// Initialize with a path
        /// - Parameter path: The URL path for the PUT request
        public init(wrappedValue: NetworkResponse? = nil, _ path: String) {
            self.path = path
            self.storage = Storage(wrappedValue)
        }

        /// Projected value provides execute method
        public var projectedValue: Put {
            self
        }

        /// Execute the PUT request
        /// - Parameter data: The data to put
        /// - Returns: The network response
        @discardableResult
        public func execute(_ data: Any? = nil) async -> NetworkResponse {
            let response = await networking.request(path: path, method: .put(data))
            storage.wrappedValue = response
            return response
        }
    }
}
