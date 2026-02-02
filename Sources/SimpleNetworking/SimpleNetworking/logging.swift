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

#if canImport(OSLog)
import OSLog
#endif

extension SimpleNetworking {
    #if canImport(OSLog)
    /// Logger for SimpleNetworking (only available on Apple platforms)
    private static let logger = Logger(
        subsystem: "nl.wesleydegroot.SimpleNetworking",
        category: "networking"
    )
    #endif

    /// Log helper that works on all platforms
    private func log(_ message: String, level: LogLevel = .info) {
        #if canImport(OSLog)
        switch level {
        case .debug:
            Self.logger.debug("\(message)")
        case .info:
            Self.logger.info("\(message)")
        case .error:
            Self.logger.error("\(message)")
        }
        #else
        // Fallback to print on platforms without OSLog (e.g., Linux)
        print("[\(level.rawValue)] \(message)")
        #endif
    }

    /// Log levels
    private enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case error = "ERROR"
    }

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
                log("Request: \(httpMethod) \(url.absoluteString)")
            }
        }
        if debug.requestHeaders, let headers = request.allHTTPHeaderFields {
            log("Headers:", level: .debug)
            for (header, cont) in headers {
                log("  \(header): \(cont)", level: .debug)
            }
        }
        if debug.requestCookies {
            log("Cookies:", level: .debug)
            if let cookies = session?.configuration.httpCookieStorage?.cookies {
                for cookie in cookies {
                    log("  \(cookie.name): \(cookie.value)", level: .debug)
                }
            } else {
                log("  No cookies", level: .debug)
            }
        }
        if debug.requestBody {
            log("Body:", level: .debug)
            if let httpBody = request.httpBody,
               let httpBodyString = String(data: httpBody, encoding: .utf8) {
                log("  \(httpBodyString)", level: .debug)
            }
        }
    }

    internal func networkLogResponse(response: HTTPURLResponse) {
        log("HTTPURLResponse: HTTP \(response.statusCode)")
        for (header, cont) in response.allHeaderFields {
            log("  \(header): \(cont)", level: .debug)
        }
    }

    internal func networkLogData(data: Data) {
        guard let stringData = String(data: data, encoding: .utf8) else {
            log("Unable to decode networkLogData", level: .error)
            return
        }

        if debug.responseBody {
            log("Body:", level: .debug)
            for line in stringData.split(separator: "\n") {
                log("  \(line)", level: .debug)
            }
        }

        if debug.responseJSON {
            log("Decoded JSON:", level: .debug)
            if let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for (key, value) in dictionary {
                    log("  \(key): \"\(value)\"", level: .debug)
                }
            } else {
                log("  Unable to parse JSON", level: .debug)
            }
        }
    }

    internal func handleNetworkError(data: Data) -> String {
        if let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            return "Unable to parse error message"
        }
    }
}
