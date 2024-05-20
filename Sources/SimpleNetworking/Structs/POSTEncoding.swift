//
//  POSTEncoding.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 26/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE
//

import Foundation

extension SimpleNetworking {
    /// Post Type
    ///
    /// The following types are supported:
    /// - `json` for JSON based posts.
    /// - `plain` for Plain text (eg own encoder).
    /// - `graphQL` for graphQL (JSON)
    public enum POSTEncoding {
        /// The type for JSON based posts.
        case json

        /// The type for plain text (eg own encoder).
        case plain

        /// The type for graphQL (JSON).
        case graphQL
    }
}
