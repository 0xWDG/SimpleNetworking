//
//  Get.swift
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
    /// Property wrapper for GET requests
    ///
    /// Usage:
    /// ```swift
    /// @Get("/users")
    /// var users: NetworkResponse?
    ///
    /// // Execute the request
    /// let response = await $users.execute()
    /// ```
    @propertyWrapper
    public struct Get {
        /// Internal storage class to avoid mutation issues
        private class Storage {
            // swiftlint:disable:previous nesting
            var wrappedValue: NetworkResponse?
            init(_ value: NetworkResponse?) {
                self.wrappedValue = value
            }
        }

        /// The URL path for the GET request
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
        /// - Parameter path: The URL path for the GET request
        public init(wrappedValue: NetworkResponse? = nil, _ path: String) {
            self.path = path
            self.storage = Storage(wrappedValue)
        }

        /// Projected value provides execute method
        public var projectedValue: Get {
            self
        }

        /// Execute the GET request
        /// - Returns: The network response
        @discardableResult
        public func execute() async -> NetworkResponse {
            let response = await networking.request(path: path, method: .get)
            storage.wrappedValue = response
            return response
        }
    }
}
