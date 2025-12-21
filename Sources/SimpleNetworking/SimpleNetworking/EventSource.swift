//
//  EventSource.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 03/10/2025.
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
    /// Start an EventSource connection to the given URL.
    /// - Parameters:
    ///   - path: The path to connect to.
    ///   - onOpen: Optional closure to call when the connection is opened.
    ///   - onMessage: Optional closure to call when a message is received.
    ///   - onError: Optional closure to call when an error occurs.
    /// - Note: Make sure to call `eventSourceDisconnect()` to close the connection when done.
    public func eventSource(
        path: String,
        onOpen: (() -> Void)? = nil,
        onMessage: @escaping ((Data) -> Void),
        onError: ((Error) -> Void)? = nil
    ) {
        guard let siteURL = self.isURL(path) else {
            return
        }

        return eventSource(
            url: siteURL,
            onOpen: onOpen,
            onMessage: onMessage,
            onError: onError
        )
    }

    /// Start an EventSource connection to the given URL.
    /// - Parameters:
    ///   - url: The URL to connect to.
    ///   - onOpen: Optional closure to call when the connection is opened.
    ///   - onMessage: Optional closure to call when a message is received.
    ///   - onError: Optional closure to call when an error occurs.
    /// - Note: Make sure to call `eventSourceDisconnect()` to close the connection when done.
    public func eventSource(
        url: URL,
        onOpen: (() -> Void)? = nil,
        onMessage: @escaping ((Data) -> Void),
        onError: ((Error) -> Void)? = nil
    ) {
        self.onOpen = onOpen
        self.onMessage = onMessage
        self.onError = onError

        ESsession = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())
        if let cookies = self.cookies {
            for cookieData in cookies {
                ESsession?.configuration.httpCookieStorage?.setCookie(cookieData)
            }
        }

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        task = ESsession?.dataTask(with: request) { _, _, error in
            if let error = error {
                self.onError?(error)
                return
            }
        }
        task?.resume()

        // Keep listening with streaming delegate
        ESsession = URLSession(
            configuration: .default,
            delegate: EventSourceDelegate(onMessage: onMessage),
            delegateQueue: nil
        )
        task = ESsession?.dataTask(with: request)
        task?.resume()
        onOpen?()
    }

    /// Disconnect the EventSource connection.
    public func eventSourceDisconnect() {
        task?.cancel()
        ESsession?.invalidateAndCancel()
    }
}

class EventSourceDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    internal var onMessage: ((Data) -> Void)?

    public init(onMessage: ((Data) -> Void)?) {
        self.onMessage = onMessage
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        onMessage?(data)
    }
}
