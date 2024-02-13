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
        var requestURL: Bool = false
        /// Debug: sent HTTP Headers
        var requestHeaders: Bool = false
        /// Debug: sent Cookies
        var requestCookies: Bool = false
        /// Debug: sent Body
        var requestBody: Bool = false
        /// Debug: received HTTP Headers
        var responseHeaders: Bool = false
        /// Debug: received Body
        var responseBody: Bool = false
        /// Debug: received JSON (if any)
        var responseJSON: Bool = false
    }
}
