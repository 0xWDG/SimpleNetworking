//
//  SNMock.swift
//
//
//  Created by Wesley de Groot on 01/03/2024.
//

import Foundation

/// Simple Networking Mock
public struct SNMock {
    /// Mocked HTTP Response data
    public let data: Data?

    /// Mocked HTTP Response
    public let response: URLResponse?

    /// Mocked HTTP Response status code
    public let statusCode: Int? = 200

    /// Mocked Error (if any)
    public let error: Error?

    /// Initialize a mocked HTTP Response
    /// - Parameters:
    ///   - data: Mocked HTTP Response data
    ///   - response: Mocked HTTP Response
    ///   - statusCode: Mocked HTTP Response status code
    ///   - error: Mocked Error (if any)
    public init(data: Data?, response: URLResponse?, statusCode: Int? = 200, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }

    /// Initialize a mocked HTTP Response
    /// - Parameters:
    ///   - data: Mocked HTTP Response data
    ///   - response: Mocked HTTP Response
    ///   - statusCode: Mocked HTTP Response status code
    ///   - error: Mocked Error (if any)
    public init(data: String?, response: URLResponse?, statusCode: Int? = 200, error: Error?) {
        self.data = data?.data(using: .utf8)
        self.response = response
        self.error = error
    }
}
