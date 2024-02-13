//
//  HTTPMethod.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

extension SimpleNetworking {
    /// HTTP Methods
    public enum HTTPMethod {
        /// HTTP GET
        case get
        /// HTTP PUT
        ///
        /// - parameters:
        ///   - value: A value to put
        case put(Any?)
        /// HTTP POST
        ///
        /// - parameters:
        ///   - value: A value to post
        case post(Any?)
        /// HTTP DELETE
        ///
        /// - parameters:
        ///   - value: A value to delete
        case delete(Any?)

        /// Method for internal use
        var method: String {
            switch self {
            case .get:
                return "GET"
            case .put:
                return "PUT"
            case .post:
                return "POST"
            case .delete:
                return "DELETE"
            }
        }
    }
}
