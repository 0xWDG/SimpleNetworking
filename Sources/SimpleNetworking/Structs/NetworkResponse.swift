//
//  NetworkResponse.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

extension SimpleNetworking {
    /// Network response
    public struct NetworkResponse {
        /// URL Response
        public var response: URLResponse?

        /// HTTP Status code
        public var statuscode: Int?

        /// Error
        public var error: Error?

        /// Received data
        public var data: Data?

        /// Received data as string
        public var string: String?

        /// Received data as JSON
        public var json: [String: Any]?

        /// Reveived cookies.
        public var cookies: [HTTPCookie]?

        /// Request
        public var request: URLRequest

        /// Decode to an Codable type
        /// - Parameter strategy: decoding strategy
        /// - Returns: T
        public func decoded<T: Codable>(
            strategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
            file: String = #file,
            line: Int = #line,
            function: String = #function
        ) -> T? {
            guard let data = data else {
                print("No data provided")
                return nil
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = strategy
                return try decoder.decode(T.self, from: data)
            } catch {
                print("\(file):\(line) \(function):\r\n Decoding error", error)
                return nil
            }
        }
    }
}
