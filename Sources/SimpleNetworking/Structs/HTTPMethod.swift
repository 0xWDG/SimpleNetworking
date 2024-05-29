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
        /// The `GET` method requests a representation of the specified resource. 
        /// Requests using `GET` should only retrieve data.
        case get

        /// The `PUT` method replaces all current representations of the target resource with the request payload.
        ///
        /// - parameters:
        ///   - value: A value to put
        case put(Any?)

        /// The `POST` method submits an entity to the specified resource,
        /// often causing a change in state or side effects on the server.
        ///
        /// - parameters:
        ///   - value: A value to post
        case post(Any?)

        /// The `DELETE` method deletes the specified resource.
        ///
        /// - parameters:
        ///   - value: A value to delete
        case delete(Any?)

        /// The `PATCH` method applies partial modifications to a resource.
        ///
        /// - parameters:
        ///   - value: A value to delete
        case patch(Any?)

        /// Method for internal use
        ///
        /// Method used for the HTTP Request.
        /// This can be `GET`, `PUT`, `POST`, `PATCH`, `DELETE`.
        var method: String {
            switch self {
            case .get:
                return "GET"
            case .put:
                return "PUT"
            case .post:
                return "POST"
            case .patch:
                return "PATCH"
            case .delete:
                return "DELETE"
            }
        }
    }
}
