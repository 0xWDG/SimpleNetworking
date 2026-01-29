//
//  Upload.swift
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
    /// Property wrapper for file upload requests
    ///
    /// Usage:
    /// ```swift
    /// @Upload("/upload")
    /// var fileUpload: NetworkResponse?
    ///
    /// // Execute the upload
    /// let response = await $fileUpload.execute(uploadData)
    /// ```
    @propertyWrapper
    public struct Upload {
        /// Internal storage class to avoid mutation issues
        private class Storage {
            // swiftlint:disable:previous nesting
            var wrappedValue: NetworkResponse?
            init(_ value: NetworkResponse?) {
                self.wrappedValue = value
            }
        }

        /// The URL path for the upload request
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
        /// - Parameter path: The URL path for the upload request
        public init(wrappedValue: NetworkResponse? = nil, _ path: String) {
            self.path = path
            self.storage = Storage(wrappedValue)
        }

        /// Projected value provides execute method
        public var projectedValue: Upload {
            self
        }

        /// Execute the upload request
        /// - Parameter uploadData: The upload data containing files and parameters
        /// - Returns: The network response
        @discardableResult
        public func execute(_ uploadData: SimpleNetworking.MultipartUploadData) async -> NetworkResponse {
            let response = await networking.upload(path: path, uploadData: uploadData)
            storage.wrappedValue = response
            return response
        }
    }
}
