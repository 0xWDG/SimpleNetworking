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

#if canImport(FoundationNetworking)
// Support network calls in Linux.
import FoundationNetworking
#endif

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

        /// Received data as Dictionary (if the data is JSON)
        public var dictionary: [String: Any]?

        /// Reveived cookies.
        public var cookies: [HTTPCookie]?

        /// Request
        public var request: URLRequest

        /// Request as cURL command.
        public var cURL: String {
            let cURL = "curl"
            let method = "-X \(request.httpMethod ?? "GET")"
            let url = request.url.flatMap { "--url '\($0.absoluteString)'" }
            var cookieString: String?
            let header = request.allHTTPHeaderFields?
                .map { "-H '\($0): \($1)'" }
                .joined(separator: " ")

            if let cookies = cookies,
               let cookieValue = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
                cookieString = "-H 'Cookie: \(cookieValue)'"
            }

            let data: String?
            if let httpBody = request.httpBody, !httpBody.isEmpty,
                var bodyString = String(data: httpBody, encoding: .utf8) {
                bodyString = bodyString.replacingOccurrences(of: "'", with: "'\\''")
                data = "--data '\(bodyString)'"
            } else {
                data = nil
            }

            return [cURL, method, url, header, cookieString, data]
                .compactMap { $0 }
                .joined(separator: " ")
        }

        /// Get the returned HTTP Headers
        public var headers: [HTTPHeader] {
            let httpURLResponse = self.response as? HTTPURLResponse
            return httpURLResponse?.allHeaderFields.compactMap {
                guard let key = $0.key as? String,
                      let value = $0.value as? String else { return nil }

                return HTTPHeader(name: key, value: value)
            } ?? []
        }

        /// Request as cURL command.
        public var asHTTPRequest: String {
            var lines: [String] = []

            lines.append("\(request.httpMethod ?? "GET") \(request.url?.relativePath ?? "/") HTTP1/1")
            lines.append("Host: \(request.url?.host ?? "")")
            lines.append("Connection: close")

            if let headerFields = request.allHTTPHeaderFields {
                for header in headerFields {
                    lines.append(header.key + ": " + header.value)
                }
            }

            if let cookies = cookies,
               let cookieValue = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
                lines.append("Cookie: \(cookieValue)")
            }

            if let httpBody = request.httpBody, !httpBody.isEmpty,
                var bodyString = String(data: httpBody, encoding: .utf8) {
                bodyString = bodyString.replacingOccurrences(of: "'", with: "'\\''")

                lines.append("")
                lines.append(bodyString)
            }

            return lines.joined(separator: "\n")
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
                return nil
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = strategy
                return try decoder.decode(T.self, from: data)
            } catch {
                print("\(file):\(line) \(function):\r\nDecoding error", error)
                print("Raw string: \"\(self.string ?? "")\".")
                return nil
            }
        }
    }
}
