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
/// This class is meant for simple networking tasks.
///
/// [https://github.com/0xWDG/SimpleNetworking](https://github.com/0xWDG/SimpleNetworking)
open class SimpleNetworking: @unchecked Sendable {
    /// Shared instance
    public static let shared = SimpleNetworking()

    /// Immutable values used to create a client. A configuration can safely be
    /// shared between tasks; changes to a client remain local to that client.
    public struct Configuration: Sendable {
        public let serverURL: String
        public let userAgent: String
        public let authorization: String?
        public let headers: [HTTPHeader]
        public let encoding: POSTEncoding

        public init(
            serverURL: String = "",
            userAgent: String = "Simple Networking (https://github.com/0xWDG/SimpleNetworking)",
            authorization: String? = nil,
            headers: [HTTPHeader] = [],
            encoding: POSTEncoding = .json
        ) {
            self.serverURL = serverURL
            self.userAgent = userAgent
            self.authorization = authorization
            self.headers = headers
            self.encoding = encoding
        }
    }

    /// Protects all mutable client state used by concurrent requests.
    internal let stateLock = NSLock()
    internal var cookieStorage: [HTTPCookie]? = []
    internal var headerStorage: [HTTPHeader]? = []
    internal var fullResponseStorage: String? = ""

    /// All the cookies. Prefer the cookie helper methods for atomic updates.
    public var cookies: [HTTPCookie]? {
        get { withStateLock { cookieStorage } }
        set { withStateLock { cookieStorage = newValue } }
    }

    /// Headers added to every request.
    public var headers: [HTTPHeader]? {
        get { withStateLock { headerStorage } }
        set { withStateLock { headerStorage = newValue } }
    }

    /// The most recently completed response body for this client.
    public var fullResponse: String? {
        get { withStateLock { fullResponseStorage } }
        set { withStateLock { fullResponseStorage = newValue } }
    }

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

    /// Streaming response handler for connection open event
    internal var onOpen: (() -> Void)?

    /// Streaming response handler for message received event
    internal var onMessage: ((Data) -> Void)?

    /// Streaming response handler for error event
    internal var onError: ((Error) -> Void)?

    /// URLSession Data Task
    internal var task: URLSessionDataTask?

    /// EventSource session
    internal var ESsession: URLSession?

    /// Websocket socket
    internal var WSSocket: URLSessionWebSocketTask?

    /// Websocket connection tries
    internal var WSConnectionTries: Int = 0

    /// Default URL (for fallback purposes)
    internal let defaultURL: URL = {
        // This is a hardcoded URL that should always be valid
        // Using a static initializer to avoid force unwrapping at the declaration site
        guard let url = URL(string: "https://wesleydegroot.nl") else {
            fatalError("Invalid hardcoded default URL - this should never happen")
        }
        return url
    }()

    /// Mock data
    internal var mockData = [String: SNMock]()

    /// Debug values
    internal var debugStorage: Debug = .init()
    public var debug: Debug {
        get { withStateLock { debugStorage } }
        set { withStateLock { debugStorage = newValue } }
    }

    /// Create an isolated networking client with immutable initial settings.
    public init(configuration: Configuration = .init(), session: URLSession? = nil) {
        serverURL = configuration.serverURL
        userAgent = configuration.userAgent
        authToken = configuration.authorization
        postEncoding = configuration.encoding
        headerStorage = configuration.headers
        self.session = session ?? URLSession(configuration: .ephemeral)
    }

    internal func withStateLock<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    internal struct RequestSettings {
        let serverURL: String
        let userAgent: String
        let authorization: String?
        let headers: [HTTPHeader]
        let session: URLSession?
        let mocks: [String: SNMock]
    }

    /// Capture settings once so one request cannot observe a partially updated
    /// configuration while another task is reconfiguring the client.
    internal func requestSettings() -> RequestSettings {
        withStateLock {
            .init(
                serverURL: serverURL,
                userAgent: userAgent,
                authorization: authToken,
                headers: headerStorage ?? [],
                session: session,
                mocks: mockData
            )
        }
    }

    /// Atomically replace the client's request configuration.
    public func set(configuration: Configuration) {
        withStateLock {
            serverURL = configuration.serverURL
            userAgent = configuration.userAgent
            authToken = configuration.authorization
            postEncoding = configuration.encoding
            headerStorage = configuration.headers
        }
    }

    /// Set the server URL
    /// - Parameter serverURL: Server URL
    public func set(serverURL: String?) {
        withStateLock { self.serverURL = serverURL ?? "" }
    }

    /// Set the User-Agent
    /// - Parameter userAgent: User Agent
    public func set(userAgent: String) {
        withStateLock { self.userAgent = userAgent }
    }

    /// Set the authorization token
    /// - Parameter authorization: authorization token
    public func set(authorization: String) {
        withStateLock { self.authToken = authorization }
    }

    /// Set the post type
    /// - Parameter encoding: post encoding
    public func set(encoding: POSTEncoding) {
        withStateLock { self.postEncoding = encoding }
    }

    /// Set the session
    /// - Parameter session: session
    public func set(session: URLSession) {
        withStateLock { self.session = session }
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

        withStateLock { self.mockData = newMockData }
    }

    /// Add or replace a stored cookie by name.
    /// - Parameter add: Cookie to store; any stored cookie with the same name is replaced.
    public func cookie(add cookie: HTTPCookie) {
        withStateLock {
            cookieStorage?.removeAll(where: { $0.name == cookie.name })
            cookieStorage?.append(cookie)
        }
    }

    /// Add header to request
    /// - Parameter add: Header to be added.
    public func headers(add header: HTTPHeader) {
        withStateLock {
            headerStorage?.removeAll(where: { $0.name == header.name })
            headerStorage?.append(header)
        }
    }

    /// Return the full networkRequestResponse
    /// - Returns: the full networkRequestResponse
    public func networkRequestResponse() -> String? {
        return withStateLock { fullResponseStorage }
    }

    // MARK: - Add values
    /// Add or replace a stored cookie by name.
    /// - Parameter add: Cookie to store; any stored cookie with the same name is replaced.
    public func add(cookie: HTTPCookie) {
        withStateLock {
            cookieStorage?.removeAll(where: { $0.name == cookie.name })
            cookieStorage?.append(cookie)
        }
    }

    /// Add header to request
    /// - Parameter add: Header to be added.
    public func add(header: HTTPHeader) {
        withStateLock {
            headerStorage?.removeAll(where: { $0.name == header.name })
            headerStorage?.append(header)
        }
    }

    /// Add header to request
    /// - Parameter add: Header to be added.
    public func add(header: String, value: String) {
        let headerStruct = HTTPHeader(name: header, value: value)
        withStateLock {
            headerStorage?.removeAll(where: { $0.name == headerStruct.name })
            headerStorage?.append(headerStruct)
        }
    }
}
