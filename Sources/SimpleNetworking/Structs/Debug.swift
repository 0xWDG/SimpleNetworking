//
//  Debug.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

extension SimpleNetworking {
    /// Debug parameters
    public struct Debug {
        /// Debug: NSURLRequest
        public var requestURL: Bool = false
        /// Debug: sent HTTP Headers
        public var requestHeaders: Bool = false
        /// Debug: sent Cookies
        public var requestCookies: Bool = false
        /// Debug: sent Body
        public var requestBody: Bool = false
        /// Debug: received HTTP Headers
        public var responseHeaders: Bool = false
        /// Debug: received Body
        public var responseBody: Bool = false
        /// Debug: received JSON (if any)
        public var responseJSON: Bool = false
    }
}
