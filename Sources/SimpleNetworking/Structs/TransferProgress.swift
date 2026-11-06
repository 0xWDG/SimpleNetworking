//
//  TransferProgress.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 25/09/2026.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

extension SimpleNetworking {
    /// A transfer's current byte counts and, when known, its completion fraction.
    public struct TransferProgress: Sendable, Equatable {
        /// Number of bytes sent or received so far.
        public let completedUnitCount: Int64

        /// Total number of bytes expected, or `nil` when the server did not provide one.
        public let totalUnitCount: Int64?

        /// A value between zero and one when the total size is known.
        public var fractionCompleted: Double? {
            guard let totalUnitCount, totalUnitCount > 0 else { return nil }
            return min(1, Double(completedUnitCount) / Double(totalUnitCount))
        }

        internal init(completedUnitCount: Int64, totalUnitCount: Int64) {
            self.completedUnitCount = completedUnitCount
            self.totalUnitCount = totalUnitCount > 0 ? totalUnitCount : nil
        }
    }

    /// A running transfer. Consume `progress` while awaiting `response`.
    public struct Transfer: @unchecked Sendable {
        public let progress: AsyncStream<TransferProgress>
        public let response: Task<NetworkResponse, Never>

        internal init(progress: AsyncStream<TransferProgress>, response: Task<NetworkResponse, Never>) {
            self.progress = progress
            self.response = response
        }

        /// Cancel the underlying asynchronous operation.
        public func cancel() {
            response.cancel()
        }
    }
}
