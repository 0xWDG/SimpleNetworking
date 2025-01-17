//
//  SimpleNetworking.swift
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

/// Simple Networking
///
/// This class is ment for simple networking tasks.
///
/// [https://github.com/0xWDG/SimpleNetworking](https://github.com/0xWDG/SimpleNetworking)
open class SimpleNetworking: @unchecked Sendable {
    /// Shared instance
    public static let shared = SimpleNetworking()

    /// All the cookies
    public var cookies: [HTTPCookie]? = []

    /// Header
    public var headers: [HTTPHeader]? = []

    /// the full networkRequestResponse
    public var fullResponse: String? = ""

    /// URL Prefix
    internal var serverURL: String = ""

    /// Custom user-agent
    internal var userAgent: String = "Simple Networking (https://github.com/0xWDG/SimpleNetworking)"

    /// Custom authorization token
    internal var authToken: String?

    /// Post Type
    internal var postEncoding: POSTEncoding = .json

    /// custom session
    internal var session: URLSession? = URLSession(configuration: .ephemeral)

    /// Websocket responder
    internal var WSResponder: ((Data) -> Void)?

    /// Websocket socket
    internal var WSSocket: URLSessionWebSocketTask?

    /// Websocket connection tries
    internal var WSConnectionTries: Int = 0

    /// Default URL
    internal let defaultURL = URL(string: "https://wesleydegroot.nl")! // swiftlint:disable:this force_unwrapping

    /// Mock data
    internal var mockData = [String: SNMock]()

    /// Debug values
    public var debug: Debug = .init()

    /// Set the server URL
    /// - Parameter serverURL: Server URL
    public func set(serverURL: String?) {
        self.serverURL = serverURL ?? ""
    }

    /// Set the User-Agent
    /// - Parameter userAgent: User Agent
    public func set(userAgent: String) {
        self.userAgent = userAgent
    }

    /// Set the authorization token
    /// - Parameter authorization: authorization token
    public func set(authorization: String) {
        self.authToken = authorization
    }

    /// Set the post type
    /// - Parameter encoding: post encoding
    public func set(encoding: POSTEncoding) {
        self.postEncoding = encoding
    }

    /// Set the session
    /// - Parameter session: session
    public func set(session: URLSession) {
        self.session = session
    }

    /// Set mock url data
    /// - Parameter mock: Mock request.
    public func set(mockData: [String: SNMock]) {
        var newMockData: [String: SNMock] = [:]

        for (url, mock) in mockData {
            if let validURL = isURL(url) {
                newMockData[validURL.absoluteString] = mock
            }
        }

        self.mockData = newMockData
    }

    /// Add a cookie to the storage
    /// - Parameter add: cookie
    public func cookie(add cookie: HTTPCookie) {
        cookies?.removeAll(where: { $0.name == cookie.name })
        cookies?.append(cookie)
    }

    /// Add header to request
    /// - Parameter add: Header to be added.
    public func headers(add header: HTTPHeader) {
        headers?.removeAll(where: { $0.name == header.name })
        headers?.append(header)
    }

    /// Return the full networkRequestResponse
    /// - Returns: the full networkRequestResponse
    public func networkRequestResponse() -> String? {
        return fullResponse
    }
}
