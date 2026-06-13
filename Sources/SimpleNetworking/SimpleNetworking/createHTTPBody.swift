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
    ///
    /// - Parameter value: Value in `[String: Codable]`, `Codable` or Plain text
    /// - Returns: Encoded data
    func createHTTPBody(with value: Any?, postType: POSTEncoding = .auto) -> Data? {
        // swiftlint:disable:previous cyclomatic_complexity function_body_length
        if let data = value as? Data {
            return data
        }

        // Determine the actual encoding to use
        let actualEncoding: POSTEncoding
        switch postType {
        case .auto:
            actualEncoding = self.postEncoding
        default:
            actualEncoding = postType
        }

        switch actualEncoding {
        case .json:
            if let contents = value as? [String: Codable] {
                do {
                    return try JSONSerialization.data(withJSONObject: contents)
                } catch {
                    log(error.localizedDescription, level: .error)
                }
            }

            if let contents = value as? Encodable {
                do {
                    return try JSONEncoder().encode(contents)
                } catch {
                    log(error.localizedDescription, level: .error)
                }
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

        case .multipart(let boundary):
            if let uploadData = value as? MultipartUploadData {
                return createMultipartBody(uploadData: uploadData, boundary: boundary)
            }

        case .auto:
            // This case is handled above, but kept for exhaustive switch
            break
        }

        return nil
    }

    /// Content-Type Header for internal use
    func getContentType(postType: POSTEncoding = .json) -> String {
        switch postType {
        case .plain:
            return "application/x-www-form-urlencoded"
        case .auto, .json, .graphQL:
            return "application/json"
        case .multipart(let boundary):
            return "multipart/form-data; boundary=\(boundary)"
        }
    }

    private func urlQueryValueAllowed() -> CharacterSet {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }

    /// Generate a random boundary string for multipart form data
    /// - Returns: A random boundary string
    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }

    /// Create multipart form data body
    /// - Parameters:
    ///   - uploadData: The multipart upload data
    ///   - boundary: The boundary string
    /// - Returns: The encoded multipart body
    private func createMultipartBody(uploadData: MultipartUploadData, boundary: String) -> Data? {
        var body = Data()

        // Add form parameters
        for (key, value) in uploadData.parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(sanitizeHeaderValue(key))\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        // Add files
        for file in uploadData.files {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; ")
            body.append("name=\"\(sanitizeHeaderValue(file.name))\"; ")
            body.append("filename=\"\(sanitizeHeaderValue(file.filename))\"\r\n")
            body.append("Content-Type: \(sanitizeHeaderValue(file.mimeType))\r\n\r\n")
            body.append(file.data)
            body.append("\r\n")
        }

        // Add closing boundary
        body.append("--\(boundary)--\r\n")

        return body
    }

    /// Sanitize header values to prevent multipart corruption
    /// - Parameter value: The value to sanitize
    /// - Returns: Sanitized value safe for use in headers
    private func sanitizeHeaderValue(_ value: String) -> String {
        // Replace quotes and control characters that could break multipart format
        return value
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

// MARK: - Data Extension for String Appending
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
