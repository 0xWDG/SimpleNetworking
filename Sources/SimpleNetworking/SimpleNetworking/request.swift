//
//  request.swift
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
    /// _Asynchronous function_ Creates a network request that retrieves the contents of a URL \
    /// based on the specified URL request object, and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - url: A value that identifies the location of a resource, \
    ///   such as an item on a remote server or the path to a local file.
    ///   - method: The HTTP request method.
    public func request(
        path: String,
        method: HTTPMethod,
        encoding: POSTEncoding = .auto,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async -> NetworkResponse {
        guard let siteURL = self.isURL(path) else {
            return .init(
                error: NetworkingError(
                    message: "Error: Request endpoint doesn't appear to be an URL"
                ),
                request: .init(url: defaultURL)
            )
        }

        // Create a URL Request
        var request = createRequest(url: siteURL)
        request.httpMethod = method.method

        switch method {
        case .delete(let data), .post(let data), .patch(let data), .put(let data):
            request.setValue(getContentType(postType: encoding), forHTTPHeaderField: "Content-Type")
            request.httpBody = createHTTPBody(with: data, postType: encoding)

        case .get:
            break
        }

        return await exec(with: request, file: file, line: line, function: function)
    }

    /// Creates a network request that retrieves the contents of a URL \
    /// based on the specified URL request object, and calls a handler upon completion.
    ///
    /// - Parameters:
    ///   - url: A value that identifies the location of a resource, \
    ///   such as an item on a remote server or the path to a local file.
    ///   - method: The HTTP request method.
    ///   - completionHandler: This completion handler takes the following parameter: [NetworkResponse](NetworkResponse)
    public func request(
        path: String,
        method: HTTPMethod,
        encoding: POSTEncoding = .auto,
        completionHandler: @escaping @Sendable (NetworkResponse) -> Void,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        guard let siteURL = self.isURL(path) else {
            completionHandler(
                .init(
                    error: NetworkingError(
                        message: "Error: Request endpoint doesn't appear to be an URL"
                    ),
                    request: .init(url: defaultURL)
                )
            )
            return
        }

        // Create a URL Request
        var request = createRequest(url: siteURL)
        request.httpMethod = method.method

        switch method {
        case .delete(let data), .post(let data), .patch(let data), .put(let data):
            request.setValue(getContentType(postType: encoding), forHTTPHeaderField: "Content-Type")
            request.httpBody = createHTTPBody(with: data, postType: encoding)

        case .get:
            break
        }

        exec(with: request, completionHandler: { response in
            completionHandler(response)
        }, file: file, line: line, function: function)
    }

    internal func createRequest(url: URL) -> URLRequest {
        // Create a URL Request
        var request = URLRequest(url: url)

        // Add the user agent
        request.addValue(
            self.userAgent,
            forHTTPHeaderField: "User-Agent"
        )

        headers?.forEach({ header in
            request.addValue(header.value, forHTTPHeaderField: header.name)
        })

        // Add the authentication token (if needed)
        if let authToken = self.authToken {
            request.setValue(
                "Bearer \(authToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        // Return the request.
        return request
    }
}
