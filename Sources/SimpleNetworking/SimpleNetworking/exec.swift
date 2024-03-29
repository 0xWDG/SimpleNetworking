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

extension SimpleNetworking {
    internal func exec(
        with request: URLRequest,
        file: String = #file,
        line: Int = #line,
        function: String = #function) async -> NetworkResponse {
            if let url = request.url,
               let mock = mockData[url.absoluteString] {
                let data = mock.data ?? .init()

                return .init(
                    response: mock.response,
                    statuscode: mock.statusCode,
                    error: mock.error,
                    data: mock.data,
                    string: String(data: data, encoding: .utf8),
                    json: try? JSONSerialization.jsonObject(
                        with: data,
                        options: []
                    ) as? [String: Any],
                    cookies: nil,
                    request: request
                )
            }

            if let cookies = SimpleNetworking.cookies {
                for cookieData in cookies {
                    // _FIXME: Can crash??
                    self.session?.configuration.httpCookieStorage?.setCookie(cookieData)
                }
            }

            guard let session = session else {
                fatalError("There is no session")
            }

            do {
                let (data, response) = try await session.data(for: request)

                // Save our cookies
                SimpleNetworking.cookies = session.configuration.httpCookieStorage?.cookies
                SimpleNetworking.fullResponse = String(data: data, encoding: .utf8)

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
                    json: try? JSONSerialization.jsonObject(
                        with: data,
                        options: []
                    ) as? [String: Any],
                    cookies: session.configuration.httpCookieStorage?.cookies,
                    request: request
                )
            } catch {
                return .init(error: error, request: request)
            }
        }

    internal func exec(
        with request: URLRequest,
        completionHandler: @escaping (NetworkResponse) -> Void,
        file: String = #file,
        line: Int = #line,
        function: String = #function) {
            if let url = request.url,
               let mock = mockData[url.absoluteString] {
                let data = mock.data ?? .init()

                completionHandler(
                    .init(
                        response: mock.response,
                        statuscode: mock.statusCode,
                        error: mock.error,
                        data: mock.data,
                        string: String(data: data, encoding: .utf8),
                        json: try? JSONSerialization.jsonObject(
                            with: data,
                            options: []
                        ) as? [String: Any],
                        cookies: nil,
                        request: request
                    )
                )
            }

            DispatchQueue.global(qos: .userInitiated).async {
                if let cookies = SimpleNetworking.cookies {
                    for cookieData in cookies {
                        // _FIXME: Can crash??
                        self.session?.configuration.httpCookieStorage?.setCookie(cookieData)
                    }
                }

                // Start our datatask
                self.session?.dataTask(with: request) { [self] (sitedata, response, taskError) in
                    // Check if we got any useable site data
                    guard let sitedata = sitedata else {
                        completionHandler(.init(error: taskError, request: request))
                        return
                    }

                    // Save our cookies
                    SimpleNetworking.cookies = session?.configuration.httpCookieStorage?.cookies
                    SimpleNetworking.fullResponse = String(data: sitedata, encoding: .utf8)

                    self.networkLog(
                        request: request, session: session, response: response, data: sitedata,
                        file: file, line: line, function: function
                    )

                    var httpCode: Int?
                    if let httpResponse = response as? HTTPURLResponse {
                        httpCode = httpResponse.statusCode
                    }

                    completionHandler(
                        .init(
                            response: response,
                            statuscode: httpCode,
                            error: taskError,
                            data: sitedata,
                            string: String(data: sitedata, encoding: .utf8),
                            json: try? JSONSerialization.jsonObject(
                                with: sitedata,
                                options: []
                            ) as? [String: Any],
                            cookies: session?.configuration.httpCookieStorage?.cookies,
                            request: request
                        )
                    )
                }.resume()
            }
        }
}
