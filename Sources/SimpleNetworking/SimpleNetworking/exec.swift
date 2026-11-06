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
               let mock = requestSettings().mocks[url.absoluteString] {
                let data = mock.data ?? .init()

                var result = NetworkResponse(
                    response: mock.response,
                    statuscode: mock.statusCode,
                    error: mock.error,
                    data: mock.data,
                    string: String(data: data, encoding: .utf8),
                    dictionary: try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    cookies: nil,
                    request: preparedRequest
                )
                result.normalizeError()
                return result
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
            guard let session = requestSettings().session else {
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

                var result = NetworkResponse(
                    response: response,
                    statuscode: httpCode,
                    error: nil,
                    data: data,
                    string: String(data: data, encoding: .utf8),
                    dictionary: try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    cookies: responseCookies,
                    request: preparedRequest
                )
                result.normalizeError()
                return result
            } catch {
                return .init(error: NetworkingError.transport(error), request: preparedRequest)
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

            if let mockedResponse = mockedResponse(for: request) {
                completionHandler(mockedResponse)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                // Start our datatask
                let session = self.requestSettings().session
                session?.dataTask(with: request) { [self] (siteData, response, taskError) in
                    // Check if we got any useable site data
                    guard let siteData = siteData else {
                        completionHandler(.init(
                            error: taskError.map(NetworkingError.transport),
                            request: request
                        ))
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

                    var result = NetworkResponse(
                        response: response,
                        statuscode: httpCode,
                        error: taskError,
                        data: siteData,
                        string: String(data: siteData, encoding: .utf8),
                        dictionary: try? JSONSerialization.jsonObject(with: siteData, options: []) as? [String: Any],
                        cookies: responseCookies,
                        request: request
                    )
                    result.normalizeError()
                    completionHandler(result)
                }.resume()
            }
        }

    /// Builds a response for a configured mock without starting a URL session.
    private func mockedResponse(for request: URLRequest) -> NetworkResponse? {
        guard let url = request.url,
              let mock = requestSettings().mocks[url.absoluteString] else {
            return nil
        }

        let data = mock.data ?? .init()
        var result = NetworkResponse(
            response: mock.response,
            statuscode: mock.statusCode,
            error: mock.error,
            data: mock.data,
            string: String(data: data, encoding: .utf8),
            dictionary: try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            cookies: nil,
            request: request
        )
        result.normalizeError()
        return result
    }
}
