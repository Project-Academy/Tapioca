//
//  Response.swift
//  Presto
//
//  Created by Sarfraz Basha on 12/11/2025.
//

import Foundation

/**
 Wraps the raw data and HTTP metadata returned by a network request.
 
 You obtain a `Response` from ``Request/response()`` and can then inspect the status code,
 headers, and body — either as raw `Data`, a parsed JSON dictionary, or a decoded `Decodable` type.
 */
public struct Response: Sendable {
    
    internal let urlResponse: URLResponse?

    //--------------------------------------
    // MARK: - VARIABLES -
    //--------------------------------------

    /// The raw response body returned by the server.
    public let data: Data

    /**
     The HTTP-specific response metadata (status code, headers, etc.).
     `nil` if the response was not an HTTP response.
     */
    public let http: HTTPURLResponse?
    
    //--------------------------------------
    // MARK: - COMPUTED VARS -
    //--------------------------------------

    /// All HTTP header fields from the response, or `nil` if unavailable.
    public var headers: [AnyHashable: Any]? { http?.allHeaderFields }

    /// The HTTP status code of the response (e.g. `200`, `404`), or `nil` if unavailable.
    public var statusCode: Int? { http?.statusCode }
    
    //--------------------------------------
    // MARK: - INITIALISERS -
    //--------------------------------------

    /**
     Creates a `Response` from the raw tuple returned by `URLSession.data(for:)`.
     - Parameter resp: A tuple of `(data: Data, url: URLResponse)`.
     */
    public init(_ resp: (data: Data, url: URLResponse)) {
        urlResponse = resp.url
        data = resp.data
        http = urlResponse as? HTTPURLResponse
    }
    
    //--------------------------------------
    // MARK: - PARSING OUTPUT -
    //--------------------------------------

    /**
     Attempts to deserialize the response body as any JSON value (object, array, or primitive).
     Returns `nil` if the data cannot be parsed as JSON.
     */
    public var anyJSON: Any? {
        try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    /**
     Attempts to deserialize the response body as a JSON object (`[String: Any]`).
     Returns `nil` if the body is not a JSON dictionary (e.g. a JSON array, HTML, or empty).
     */
    public var json: [String: Any]? {
        anyJSON as? [String: Any]
    }

    /**
     Decodes the response body into the specified `Decodable` type using `JSONDecoder`.
     
     - Parameter type: The target type to decode into. Can be inferred from context.
     - Returns: A decoded instance of `T`.
     - Throws: A `DecodingError` if the data does not match the expected type.
     */
    public func asType<T: Decodable>(_ type: T.Type = T.self) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}
