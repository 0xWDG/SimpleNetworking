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

#if canImport(OSLog)
import OSLog
#endif

extension SimpleNetworking {
    /// Network response
    public struct NetworkResponse: CustomStringConvertible, @unchecked Sendable {
        #if canImport(OSLog)
        /// Logger for NetworkResponse (only available on Apple platforms)
        private static let logger = Logger(
            subsystem: "nl.wesleydegroot.SimpleNetworking",
            category: "decoding"
        )
        #endif

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

        /// Received cookies.
        public var cookies: [HTTPCookie]?

        /// Request
        public var request: URLRequest

        /// Whether this response has a 2xx HTTP status and no transport error.
        public var isSuccess: Bool {
            error == nil && (statuscode.map { (200...299).contains($0) } ?? false)
        }

        /// A bounded, UTF-8 diagnostic body suitable for error reporting.
        public var bodySnippet: String? {
            guard let string else { return nil }
            return String(string.prefix(4_096))
        }

        /// The structured error produced by this library, when available.
        public var networkingError: NetworkingError? {
            error as? NetworkingError
        }

        /// A readable summary that includes the originating HTTP request and its cURL equivalent.
        public var description: String {
            let status = statuscode.map(String.init) ?? "unknown"
            let responseBody = string.map { "\nResponse body:\n\($0)" } ?? ""
            return """
            NetworkResponse(status: \(status))
            Request:
            \(asHTTPRequest)
            cURL:
            \(asCURL)\(responseBody)
            """
        }

        internal mutating func normalizeError() {
            if let error, !(error is NetworkingError) {
                self.error = NetworkingError.transport(error)
            } else if error == nil,
                      let statuscode,
                      !(200...299).contains(statuscode) {
                error = NetworkingError.httpStatus(response: self)
            }
        }

        /// Request as cURL command.
        public var cURL: String {
            let cURL = "curl"
            let method = "-X \(request.httpMethod ?? "GET")"
            let url = request.url.flatMap { "--url '\($0.absoluteString)'" }
            let header = request.allHTTPHeaderFields?
                .map { "-H '\($0): \($1)'" }
                .joined(separator: " ")

            let data: String?
            if let httpBody = request.httpBody, !httpBody.isEmpty,
                var bodyString = String(data: httpBody, encoding: .utf8) {
                bodyString = bodyString.replacingOccurrences(of: "'", with: "'\\''")
                data = "--data '\(bodyString)'"
            } else {
                data = nil
            }

            return [cURL, method, url, header, data]
                .compactMap { $0 }
                .joined(separator: " ")
        }

        /// Request as a cURL command.
        public var asCURL: String {
            cURL
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

            if let httpBody = request.httpBody, !httpBody.isEmpty,
                var bodyString = String(data: httpBody, encoding: .utf8) {
                bodyString = bodyString.replacingOccurrences(of: "'", with: "'\\''")

                lines.append("")
                lines.append(bodyString)
            }

            return lines.joined(separator: "\n")
        }

        /// Decode to a Codable type, preserving detailed failure information.
        public func decode<T: Decodable>(
            _ type: T.Type = T.self,
            strategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
        ) throws -> T {
            guard let data else {
                throw NetworkingError(
                    kind: .decoding,
                    message: "Cannot decode an empty response",
                    statusCode: statuscode,
                    responseHeaders: headers,
                    bodySnippet: bodySnippet
                )
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = strategy
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkingError.decoding(error, response: self)
            }
        }

        /// Decode to a Codable type.
        /// - Parameter strategy: decoding strategy
        /// - Returns: T
        public func decoded<T: Decodable>(
            strategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
            file: String = #file,
            line: Int = #line,
            function: String = #function
        ) -> T? {
            do {
                return try decode(T.self, strategy: strategy)
            } catch {
                #if canImport(OSLog)
                Self.logger.error("Decoding error at \(file):\(line) \(function): \(error.localizedDescription)")
                Self.logger.debug("Raw string: \"\(self.string ?? "")\"")
                #else
                print("[ERROR] Decoding error at \(file):\(line) \(function): \(error)")
                print("[DEBUG] Raw string: \"\(self.string ?? "")\"")
                #endif
                return nil
            }
        }
    }
}
