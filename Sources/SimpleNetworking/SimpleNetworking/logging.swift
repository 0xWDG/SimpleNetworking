//
//  logging.swift
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
    internal func networkLog(request: URLRequest?,
                             session: URLSession?,
                             response: URLResponse?,
                             data: Data?,
                             file: String = #file,
                             line: Int = #line,
                             function: String = #function) {
        if let request = request {
            self.networkLogRequest(request: request)
        }

        if debug.responseHeaders,
           let response = response as? HTTPURLResponse {
            self.networkLogResponse(response: response)
        }

        if let data = data {
            self.networkLogData(data: data)
        }
    }

    internal func networkLogRequest(request: URLRequest) {
        if [
            debug.requestURL,
            debug.requestBody,
            debug.requestCookies,
            debug.requestHeaders,
            debug.responseHeaders,
            debug.responseBody,
            debug.responseJSON
        ].contains(true) {
            if let httpMethod = request.httpMethod,
               let url = request.url {
                print("\nRequest:")
                print("  \(httpMethod) \(url)")
            }
        }
        if debug.requestHeaders, let headers = request.allHTTPHeaderFields {
            print("\n  Headers:")
            for (header, cont) in headers {
                print("    \(header): \(cont)")
            }
        }
        if debug.requestCookies {
            print("\n  Cookies:")
            if let cookies = session?.configuration.httpCookieStorage?.cookies {
                for cookie in cookies {
                    print("    \(cookie.name): \(cookie.value)")
                }
            } else {
                print("    No cookies")
            }
        }
        if debug.requestBody {
            print("\n  Body:")
            if let httpBody = request.httpBody {
                print("    \(String(decoding: httpBody, as: UTF8.self))")
            }
        }
    }

    internal func networkLogResponse(response: HTTPURLResponse) {
        print("\nHTTPURLResponse:")
        print("  HTTP \(response.statusCode)")
        for (header, cont) in response.allHeaderFields {
            print("    \(header): \(cont)")
        }
    }

    internal func networkLogData(data: Data) {
        let stringData = String(decoding: data, as: UTF8.self)

        if debug.responseBody {
            print("\n  Body:")
            for line in stringData.split(separator: "\n") {
                print("    \(line)")
            }
        }

        if debug.responseJSON {
            print("\n  Decoded JSON:")
            if let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for (key, value) in dictionary {
                    print("    \(key): \"\(value)\"")
                }
            } else {
                print("    Unable to parse JSON")
            }
        }
    }

    internal func handleNetworkError(data: Data) -> String {
        return String(decoding: data, as: UTF8.self)
    }
}
