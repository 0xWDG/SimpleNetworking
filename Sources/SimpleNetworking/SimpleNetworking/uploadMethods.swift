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
    /// Upload multipart files from disk without loading their content into memory.
    public func upload(
        path: String,
        fileUploadData: FileBackedMultipartUploadData,
        onProgress: @escaping @Sendable (TransferProgress) -> Void = { _ in }
    ) async -> NetworkResponse {
        guard let request = createFileBackedUploadRequest(path: path) else {
            return .init(error: NetworkingError.invalidURL(path), request: .init(url: defaultURL))
        }

        do {
            let bodyFile = try createMultipartBodyFile(fileUploadData, boundary: request.boundary)
            defer { try? FileManager.default.removeItem(at: bodyFile) }
            return await uploadFileBackedRequest(request.request, bodyFile: bodyFile, onProgress: onProgress)
        } catch {
            return .init(error: NetworkingError.transport(error), request: request.request)
        }
    }

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
    internal func createUploadRequest(path: String, uploadData: MultipartUploadData) -> URLRequest? {
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

    private func createFileBackedUploadRequest(path: String) -> (request: URLRequest, boundary: String)? {
        guard let siteURL = isURL(path) else { return nil }
        let boundary = generateBoundary()
        var request = createRequest(url: siteURL)
        request.httpMethod = "POST"
        request.setValue(getContentType(postType: .multipart(boundary: boundary)), forHTTPHeaderField: "Content-Type")
        return (request, boundary)
    }

    private func createMultipartBodyFile(
        _ uploadData: FileBackedMultipartUploadData,
        boundary: String
    ) throws -> URL {
        let bodyFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("SimpleNetworking-\(UUID().uuidString).multipart")
        FileManager.default.createFile(atPath: bodyFile.path, contents: nil)
        let output = try FileHandle(forWritingTo: bodyFile)
        defer { try? output.close() }

        func write(_ value: String) throws {
            try output.write(contentsOf: Data(value.utf8))
        }

        for (key, value) in uploadData.parameters {
            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"\(sanitizeHeaderValue(key))\"\r\n\r\n")
            try write("\(value)\r\n")
        }

        for file in uploadData.files {
            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"\(sanitizeHeaderValue(file.name))\"; ")
            try write("filename=\"\(sanitizeHeaderValue(file.filename))\"\r\n")
            try write("Content-Type: \(sanitizeHeaderValue(file.mimeType))\r\n\r\n")

            let input = try FileHandle(forReadingFrom: file.fileURL)
            defer { try? input.close() }
            while let chunk = try input.read(upToCount: 64 * 1_024), !chunk.isEmpty {
                try output.write(contentsOf: chunk)
            }
            try write("\r\n")
        }

        try write("--\(boundary)--\r\n")
        return bodyFile
    }

    private func uploadFileBackedRequest(
        _ request: URLRequest,
        bodyFile: URL,
        onProgress: @escaping @Sendable (TransferProgress) -> Void
    ) async -> NetworkResponse {
        var preparedRequest = request
        addStoredCookies(to: &preparedRequest)
        let bodySize = (try? bodyFile.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0

        if let url = preparedRequest.url,
           let mock = requestSettings().mocks[url.absoluteString] {
            onProgress(.init(completedUnitCount: bodySize, totalUnitCount: bodySize))
            return response(from: mock.data, response: mock.response, error: mock.error, request: preparedRequest)
        }

        let delegate = TransferDelegate(progressHandler: onProgress)
        let configuration = requestSettings().session?.configuration ?? .ephemeral
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        var response = await delegate.upload(session: session, request: preparedRequest, bodyFile: bodyFile)
        saveCookies(from: response.response)
        response.cookies = cookieSnapshot()
        return response
    }
}
