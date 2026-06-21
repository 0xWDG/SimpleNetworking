//
//  exec.swift
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
@preconcurrency import FoundationNetworking
#endif

extension SimpleNetworking {
    /// Execute request
    /// - Parameters:
    ///   - request: URL Request
    ///   - file: Caller's filename
    ///   - line: Caller's line number
    ///   - function: Caller's function name
    /// - Returns: ``NetworkResponse``
    internal func exec( // swiftlint:disable:this function_body_length
        with request: URLRequest,
        file: String = #file,
        line: Int = #line,
        function: String = #function) async -> NetworkResponse {
            var preparedRequest = request
            addStoredCookies(to: &preparedRequest)

            if let url = preparedRequest.url,
               let mock = mockData[url.absoluteString] {
                let data = mock.data ?? .init()

                return .init(
                    response: mock.response,
                    statuscode: mock.statusCode,
                    error: mock.error,
                    data: mock.data,
                    string: String(data: data, encoding: .utf8),
                    dictionary: try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    cookies: nil,
                    request: preparedRequest
                )
            }

            #if canImport(FoundationNetworking)
            // Linux support.
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    exec(with: request, completionHandler: { response in
                        continuation.resume(returning: response)
                    }, file: file, line: line, function: function)
                }
            } catch {
                return .init(error: error, request: request)
            }
            #else
            guard let session = session else {
                return .init(
                    error: NetworkingError(message: "No URLSession available"),
                    request: preparedRequest
                )
            }

            do {
                let (data, response) = try await session.data(for: preparedRequest)

                saveCookies(from: response)
                let responseCookies = cookieSnapshot()

                fullResponse = String(data: data, encoding: .utf8)

                networkLog(
                    request: request, session: session, response: response, data: data,
                    file: file, line: line, function: function
                )

                var httpCode: Int?
                if let httpResponse = response as? HTTPURLResponse {
                    httpCode = httpResponse.statusCode
                }

                return .init(
                    response: response,
                    statuscode: httpCode,
                    error: nil,
                    data: data,
                    string: String(data: data, encoding: .utf8),
                    dictionary: try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    cookies: responseCookies,
                    request: preparedRequest
                )
            } catch {
                return .init(error: error, request: preparedRequest)
            }
            #endif
        }

    /// Execute request (legacy, non-async)
    /// - Parameters:
    ///   - request: URL Request
    ///   - file: Caller's filename
    ///   - line: Caller's line number
    ///   - function: Caller's function name
    /// - Returns: ``NetworkResponse``
    internal func exec(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (NetworkResponse) -> Void,
        file: String = #file,
        line: Int = #line,
        function: String = #function) {
            var preparedRequest = request
            addStoredCookies(to: &preparedRequest)
            let request = preparedRequest

            if let url = request.url,
               let mock = mockData[url.absoluteString] {
                let data = mock.data ?? .init()

                completionHandler(.init(
                    response: mock.response,
                    statuscode: mock.statusCode,
                    error: mock.error,
                    data: mock.data,
                    string: String(data: data, encoding: .utf8),
                    dictionary: try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    cookies: nil,
                    request: request
                ))
            }

            DispatchQueue.global(qos: .userInitiated).async {
                // Start our datatask
                self.session?.dataTask(with: request) { [self] (siteData, response, taskError) in
                    // Check if we got any useable site data
                    guard let siteData = siteData else {
                        completionHandler(.init(error: taskError, request: request))
                        return
                    }

                    // Save our cookies
                    saveCookies(from: response)
                    let responseCookies = cookieSnapshot()
                    fullResponse = String(data: siteData, encoding: .utf8)

                    self.networkLog(
                        request: request, session: session, response: response, data: siteData,
                        file: file, line: line, function: function
                    )

                    var httpCode: Int?
                    if let httpResponse = response as? HTTPURLResponse {
                        httpCode = httpResponse.statusCode
                    }

                    completionHandler(.init(
                        response: response,
                        statuscode: httpCode,
                        error: taskError,
                        data: siteData,
                        string: String(data: siteData, encoding: .utf8),
                        dictionary: try? JSONSerialization.jsonObject(with: siteData, options: []) as? [String: Any],
                        cookies: responseCookies,
                        request: request
                    ))
                }.resume()
            }
        }
}
