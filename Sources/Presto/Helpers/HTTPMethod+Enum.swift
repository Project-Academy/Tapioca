//
//  HTTPMethod+Enum.swift
//  Presto
//
//  Created by Sarfraz Basha on 12/11/2025.
//

import Foundation

/// The HTTP method to use for a network request.
public enum HTTPMethod: String, Sendable {
    /// Retrieve a resource. Parameters are encoded as URL query items.
    case GET
    /// Submit a new resource or trigger an action. Parameters are encoded in the request body.
    case POST
    /// Replace an existing resource entirely. Parameters are encoded in the request body.
    case PUT
    /// Remove a resource. Parameters are encoded in the request body.
    case DELETE
    /// Apply a partial update to an existing resource. Parameters are encoded in the request body.
    case PATCH
}
