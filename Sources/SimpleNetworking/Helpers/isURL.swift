//
//  isURL.swift
//  Simple Networking
//
//  Created by Wesley de Groot on 13/02/2024.
//  https://wesleydegroot.nl
//
//  https://github.com/0xWDG/SimpleNetworking
//  MIT LICENCE

import Foundation

extension SimpleNetworking {
    /// Is this a valid URL
    /// - Parameter urlInput: URL String
    /// - Returns: URL
    internal func isURL(_ urlInput: String) -> URL? {
        if let siteURL = URL(string: urlInput),
           urlInput.contains("://") {
            return siteURL
        }

        if let siteURL = URL(string: serverURL + urlInput) {
            return siteURL
        }

        return nil
    }
}
