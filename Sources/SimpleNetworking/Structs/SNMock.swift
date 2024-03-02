//
//  SNMock.swift
//
//
//  Created by Wesley de Groot on 01/03/2024.
//

import Foundation

/// Simple Networking Mock
public struct SNMock {
    public let data: Data?
    public let response: URLResponse?
    public let statusCode: Int? = 200
    public let error: Error?

    public init(data: Data?, response: URLResponse?, statusCode: Int? = 200, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }

    public init(data: String?, response: URLResponse?, statusCode: Int? = 200, error: Error?) {
        self.data = data?.data(using: .utf8)
        self.response = response
        self.error = error
    }
}
