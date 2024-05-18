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
        
        /// Request as cURL command.
        public var cURL: String {
            let cURL = "curl"
            let method = "-X \(request.httpMethod ?? "GET")"
            let url = request.url.flatMap { "--url '\($0.absoluteString)'" }
            var cookieString: String? = nil
            let header = request.allHTTPHeaderFields?
                .map { "-H '\($0): \($1)'" }
                .joined(separator: " ")


            if let cookies = cookies,
               let cookieValue = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
                cookieString = "-H 'Cookie: \(cookieValue)'"
            }

            let data: String?
            if let httpBody = request.httpBody, !httpBody.isEmpty {
                if let bodyString = String(data: httpBody, encoding: .utf8) { // json and plain text
                    let escaped = bodyString
                        .replacingOccurrences(of: "'", with: "'\\''")
                    data = "--data '\(escaped)'"
                } else { // Binary data
                    let hexString = httpBody
                        .map { String(format: "%02X", $0) }
                        .joined()
                    data = #"--data "$(echo '\#(hexString)' | xxd -p -r)""#
                }
            } else {
                data = nil
            }

            return [cURL, method, url, header, cookieString, data]
                .compactMap { $0 }
                .joined(separator: " ")
        }

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
                print("\(file):\(line) \(function):\r\nDecoding error", error)
                return nil
            }
        }
    }
}
