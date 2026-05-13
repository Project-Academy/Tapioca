//
//  Errors.swift
//  Presto
//
//  Created by Sarfraz Basha on 12/11/2025.
//

import Foundation

//--------------------------------------
// MARK: - ERRORS -
//--------------------------------------
/// Errors that can occur during the construction or modification of a network request URL.
public enum PrestoError: Error {
    /// Thrown when the URL in the request is missing or cannot be parsed into components.
    case invalidURL
    /// Thrown when the `URLComponents` cannot be reconstructed into a valid URL after modifications.
    case urlConstructionFailure
    /// Thrown when the HTTP response does not include a status code (i.e. the response is not an `HTTPURLResponse`).
    case noStatusCode
}
