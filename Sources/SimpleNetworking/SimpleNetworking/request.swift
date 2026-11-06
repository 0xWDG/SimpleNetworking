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
    /// Execute an immutable request description.
    public func execute(
        _ requestDescription: Request,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async -> NetworkResponse {
        guard let baseURL = isURL(requestDescription.path),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return .init(
                error: NetworkingError.invalidURL(requestDescription.path),
                request: .init(url: defaultURL)
            )
        }

        components.queryItems = (components.queryItems ?? []) + requestDescription.query
        guard let url = components.url else {
            return .init(
                error: NetworkingError.invalidURL(requestDescription.path),
                request: .init(url: defaultURL)
            )
        }

        var request = createRequest(url: url)
        request.timeoutInterval = requestDescription.timeout ?? request.timeoutInterval
        if let cachePolicy = requestDescription.cachePolicy {
            request.cachePolicy = cachePolicy
        }

        requestDescription.headers.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }

        if let customMethod = requestDescription.customMethod {
            request.httpMethod = customMethod
            request.httpBody = requestDescription.body
        } else if let method = requestDescription.method {
            request.httpMethod = method.method
            switch method {
            case .delete(let data), .post(let data), .patch(let data), .put(let data):
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    let contentType = getContentType(postType: requestDescription.encoding)
                    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                }
                request.httpBody = createHTTPBody(with: data, postType: requestDescription.encoding)
            case .get:
                break
            }
        }

        return await exec(with: request, file: file, line: line, function: function)
    }

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
    @available(*, deprecated, message: "Use async/await version instead for better concurrency support")
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
        let settings = requestSettings()
        // Create a URL Request
        var request = URLRequest(url: url)

        // Add the user agent
        request.addValue(
            settings.userAgent,
            forHTTPHeaderField: "User-Agent"
        )

        settings.headers.forEach({ header in
            request.addValue(header.value, forHTTPHeaderField: header.name)
        })

        // Add the authentication token (if needed)
        if let authToken = settings.authorization {
            request.setValue(
                "Bearer \(authToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        // Return the request.
        return request
    }
}
