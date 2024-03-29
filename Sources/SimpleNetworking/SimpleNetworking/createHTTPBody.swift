//
//  createHTTPBody.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 26/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE
//

import Foundation

extension SimpleNetworking {
    /// httpBody Method for internal use
    func createHTTPBody(with value: Any?) -> Data? {
        switch self.postType {
        case .json:
            if let contents = value as? [String: Codable] {
                return try? JSONSerialization.data(withJSONObject: contents)
            }

            if let contents = value as? Codable {
                return try? JSONEncoder().encode(contents)
            }

        case .plain:
            if let contents = value as? String {
                return contents.data(using: .utf8)
            }

            if let contents = value as? [String: Codable] {
                return contents.map { key, value in
                    let escapedKey = "\(key)".addingPercentEncoding(
                        withAllowedCharacters: urlQueryValueAllowed()
                    ) ?? ""
                    let escapedValue = "\(value)".addingPercentEncoding(
                        withAllowedCharacters: urlQueryValueAllowed()
                    ) ?? ""
                    return escapedKey + "=" + escapedValue
                }
                .joined(separator: "&")
                .data(using: .utf8)
            }

            if let contents = value as? [String: Any] {
                return contents.map { key, value in
                    let escapedKey = "\(key)".addingPercentEncoding(
                        withAllowedCharacters: urlQueryValueAllowed()
                    ) ?? ""
                    let escapedValue = "\(value)".addingPercentEncoding(
                        withAllowedCharacters: urlQueryValueAllowed()
                    ) ?? ""
                    return escapedKey + "=" + escapedValue
                }
                .joined(separator: "&")
                .data(using: .utf8)
            }

        case .graphQL:
            if let query = value as? String {
                return try? JSONSerialization.data(withJSONObject: [
                    "query": query
                ])
            }
        }

        return nil
    }

    /// Content-Type Header for internal use
    func getContentType() -> String {
        switch postType {
        case .plain:
            return "application/x-www-form-urlencoded"
        case .json, .graphQL:
            return "application/json"
        }
    }

    private func urlQueryValueAllowed() -> CharacterSet {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }
}
