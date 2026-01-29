//
//  uploadMethods.swift
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
    /// _Asynchronous function_ Uploads files using multipart/form-data encoding
    ///
    /// - Parameters:
    ///   - path: The upload endpoint path
    ///   - uploadData: The multipart upload data containing files and optional parameters
    ///   - file: Caller's filename
    ///   - line: Caller's line number
    ///   - function: Caller's function name
    /// - Returns: NetworkResponse
    public func upload(
        path: String,
        uploadData: MultipartUploadData,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async -> NetworkResponse {
        let request = createUploadRequest(path: path, uploadData: uploadData)

        guard let urlRequest = request else {
            return .init(
                error: NetworkingError(
                    message: "Error: Upload endpoint doesn't appear to be an URL"
                ),
                request: .init(url: defaultURL)
            )
        }

        return await exec(with: urlRequest, file: file, line: line, function: function)
    }

    /// Uploads files using multipart/form-data encoding (closure-based)
    ///
    /// - Parameters:
    ///   - path: The upload endpoint path
    ///   - uploadData: The multipart upload data containing files and optional parameters
    ///   - completionHandler: Completion handler with NetworkResponse
    ///   - file: Caller's filename
    ///   - line: Caller's line number
    ///   - function: Caller's function name
    @available(*, deprecated, message: "Use async/await version instead for better concurrency support")
    public func upload(
        path: String,
        uploadData: MultipartUploadData,
        completionHandler: @escaping @Sendable (NetworkResponse) -> Void,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        let request = createUploadRequest(path: path, uploadData: uploadData)

        guard let urlRequest = request else {
            completionHandler(
                .init(
                    error: NetworkingError(
                        message: "Error: Upload endpoint doesn't appear to be an URL"
                    ),
                    request: .init(url: defaultURL)
                )
            )
            return
        }

        exec(with: urlRequest, completionHandler: completionHandler, file: file, line: line, function: function)
    }

    /// Create a URLRequest for file upload
    /// - Parameters:
    ///   - path: The upload endpoint path
    ///   - uploadData: The multipart upload data
    /// - Returns: URLRequest or nil if URL is invalid
    private func createUploadRequest(path: String, uploadData: MultipartUploadData) -> URLRequest? {
        guard let siteURL = self.isURL(path) else {
            return nil
        }

        // Generate a boundary for multipart form data
        let boundary = generateBoundary()

        // Create a URL Request
        var request = createRequest(url: siteURL)
        request.httpMethod = "POST"

        // Set the content type with boundary
        request.setValue(
            getContentType(postType: .multipart(boundary: boundary)),
            forHTTPHeaderField: "Content-Type"
        )

        // Create the multipart body
        request.httpBody = createHTTPBody(
            with: uploadData,
            postType: .multipart(boundary: boundary)
        )

        return request
    }
}
