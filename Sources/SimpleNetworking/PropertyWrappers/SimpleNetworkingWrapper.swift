//
//  SimpleNetworkingWrapper.swift
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
    /// Generic property wrapper for any HTTP method
    ///
    /// Usage:
    /// ```swift
    /// @SimpleNetworkingWrapper(.get, "/users")
    /// var users: NetworkResponse?
    ///
    /// // Execute the request
    /// let response = await $users.execute()
    /// // or with data
    /// let response = await $users.execute(["key": "value"])
    /// ```
    ///
    /// - Note: When initializing with a method that has associated data (e.g., `.post(data)`),
    ///   and then calling `execute(_:)` with new data, the new data will replace the initial data.
    ///   For GET requests, the provided data parameter in `execute(_:)` is ignored.
    @propertyWrapper
    public struct SimpleNetworkingWrapper {
        /// Internal storage class to avoid mutation issues
        private class Storage {
            // swiftlint:disable:previous nesting
            var wrappedValue: NetworkResponse?
            init(_ value: NetworkResponse?) {
                self.wrappedValue = value
            }
        }

        /// The HTTP method to use
        public let method: HTTPMethod

        /// The URL path for the request
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

        /// Initialize with a method and path
        /// - Parameters:
        ///   - method: The HTTP method (without associated value for GET)
        ///   - path: The URL path for the request
        public init(wrappedValue: NetworkResponse? = nil, _ method: HTTPMethod, _ path: String) {
            self.method = method
            self.path = path
            self.storage = Storage(wrappedValue)
        }

        /// Projected value provides execute method
        public var projectedValue: SimpleNetworkingWrapper {
            self
        }

        /// Execute the request
        /// - Returns: The network response
        @discardableResult
        public func execute() async -> NetworkResponse {
            let response = await networking.request(path: path, method: method)
            storage.wrappedValue = response
            return response
        }

        /// Execute the request with data (for POST, PUT, DELETE, PATCH methods)
        /// - Parameter data: The data to send. This will replace any data that was provided
        ///   during initialization. For GET requests, this parameter is ignored.
        /// - Returns: The network response
        @discardableResult
        public func execute(_ data: Any?) async -> NetworkResponse {
            let methodWithData: HTTPMethod
            switch method {
            case .get:
                // GET requests don't use data, so we ignore the parameter
                methodWithData = .get
            case .post:
                // Replace any existing data with the new data
                methodWithData = .post(data)
            case .put:
                // Replace any existing data with the new data
                methodWithData = .put(data)
            case .delete:
                // Replace any existing data with the new data
                methodWithData = .delete(data)
            case .patch:
                // Replace any existing data with the new data
                methodWithData = .patch(data)
            }

            let response = await networking.request(path: path, method: methodWithData)
            storage.wrappedValue = response
            return response
        }
    }
}
