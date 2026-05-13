//
//  Request.swift
//  Presto
//
//  Created by Sarfraz Basha on 12/11/2025.
//

import Foundation

/**
 A fluent builder-pattern wrapper on `URLRequest` for configuring and finalizing network calls.
 
 This struct holds configuration state and defers the construction of the final `urlRequest` until the `build()`
 function is called, ensuring that complex logic like URL encoding and body serialization runs only once.
 */
public struct Request: Sendable {
    public var urlRequest: URLRequest
    public let httpMethod: HTTPMethod
    public let baseURL: URL
    
    //--------------------------------------
    // MARK: - INTERNAL STATE -
    //--------------------------------------
    public private(set) var headers: [String: String] = [:]
    public private(set) var params: [String: (any Sendable)] = [:]
    private static let defaultContentType: ContentType = .JSON
    
    /**
     A closure that serializes the `params` dictionary into `Data` for the request body.
     
     By default this produces pretty-printed JSON. Override this property to use a custom
     encoding strategy (e.g. compact JSON, a different key-naming convention, etc.).
     
     Only used when `content` is `.JSON`. Form-encoded bodies use `formatForm(_:)` instead.
     */
    public var paramTransformer: (@Sendable ([String: Any]) throws -> Data) = { params in
        try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
    }
    
    //--------------------------------------
    // MARK: - INITIALISERS -
    //--------------------------------------
    /**
     Creates a new `Request` with the given base URL and HTTP method.

     - Parameters:
       - url: The endpoint URL for this request.
       - method: The ``HTTPMethod`` to use (e.g. `.GET`, `.POST`).
     */
    public init(url: URL, _ method: HTTPMethod) {
        baseURL = url
        urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        httpMethod = method
    }

    /**
     Creates a new `Request` from a URL string and HTTP method.

     - Parameters:
       - urlString: The endpoint URL as a string.
       - method: The ``HTTPMethod`` to use (e.g. `.GET`, `.POST`).
     - Throws: ``PrestoError/invalidURL`` if the string is not a valid URL.
     */
    public init(_ urlString: String, _ method: HTTPMethod) throws {
        guard let url = URL(string: urlString)
        else { throw PrestoError.invalidURL }
        self.init(url: url, method)
    }
    
    //--------------------------------------
    // MARK: - MODIFIERS -
    //--------------------------------------
    /**
     Sets a custom HTTP header field for the request.
     
     This modifier can be used to set common headers like `Authorization` or custom headers.
     The header is stored internally and applied to the `urlRequest` when `build()` is called.
     
     - Parameters:
       - value: The value for the HTTP header (e.g., a bearer token, or 'Keep-Alive').
       - headerKey: The name of the header field.
     - Returns: A new ``Request`` instance with the updated header.
     */
    public func setHeader(key headerKey: String, value: String) -> Self {
        var request = self
        request.headers[headerKey] = value
        return request
    }
    /**
     Sets the parameters to be used in the request.
     
     For `.GET` requests, these parameters become URL query items.
     For `.POST`, `.PUT`, or `.DELETE` requests, these parameters become the HTTP body (e.g., JSON payload).
     - Parameter dict: A dictionary of parameters.
     - Returns: A new ``Request`` instance with updated parameters.
     */
    public func params(_ dict: [String: (any Sendable)]) -> Self {
        var request = self
        for (key, value) in dict {
            request.params[key] = value
        }
        return request
    }
    
    //--------------------------------------
    // MARK: - CONVENIENCE MODIFIERS -
    //--------------------------------------
    /**
     Sets the "Content-Type" header for the request.
     
     - Parameters:
       - type: The desired ``ContentType`` (e.g., `.JSON`).
     - Returns: A new ``Request`` instance with updated content type.
     */
    public func content(type: ContentType) -> Self {
        setHeader(key: "Content-Type", value: type.rawValue)
    }
    /**
     Sets the 'Accept' header for the request.
     
     - Parameters:
       - type: The expected ``ContentType`` (e.g., `.JSON`) to receive from the server.
     - Returns: A new ``Request`` instance with updated content type.
     */
    public func accepts(type: ContentType) -> Self {
        setHeader(key: "Accept", value: type.rawValue)
    }
    
    //--------------------------------------
    // MARK: - BUILDER -
    //--------------------------------------
    /**
     Finalises the request by encoding all parameters and applying all headers to the underlying `URLRequest`.
     
     You do not need to call this manually when using ``response()`` or ``response(as:)``,
     as they call `build()` internally. Use this directly if you need access to the
     configured `URLRequest` before sending it.
     
     - Returns: A new ``Request`` with a fully configured `urlRequest`.
     - Throws: ``PrestoError/invalidURL`` or ``PrestoError/urlConstructionFailure`` if the URL cannot be built,
       or any error thrown by a custom `paramTransformer`.
     */
    public func build() throws -> Self {
        try buildRequest()
    }
    private func buildRequest() throws -> Self {
        var updated = self
        var urlReq = updated.urlRequest
        
        // HEADERS
        for (key, value) in updated.headers {
            urlReq.setHeader(key: key, value: value)
        }
        
        // PARAMS
        switch updated.httpMethod {
        case .GET:
            try urlReq.updateURL(with: updated.params)
        default:
            let key = ContentType.contentKey
            let contentHeader = updated.headers[key] ?? Self.defaultContentType.rawValue
            if updated.headers[key] == nil {
                urlReq.setHeader(key: key, value: contentHeader)
            }
            switch ContentType.from(contentHeader) {
            case .JSON:
                urlReq.httpBody = try updated.paramTransformer(updated.params)
            case .Form:
                urlReq.formatForm(updated.params)
            default: break
            }
        }
        updated.urlRequest = urlReq
        return updated
    }
    
    //--------------------------------------
    // MARK: - RESPONSE -
    //--------------------------------------
    /**
     Builds and fires the request, returning the raw ``Response``.
     
     This method calls ``build()`` internally, so there is no need to call it separately.
     
     - Returns: A ``Response`` containing the response data and HTTP metadata.
     - Throws: Any error from ``build()``, or a networking error from `URLSession`.
     */
    public func response() async throws -> Response {
        let urlReq = try build().urlRequest
        let urlResp = try await URLSession.shared.data(for: urlReq)
        let response = Response(urlResp)
        return response
    }

    /**
     Builds and fires the request, then decodes the response body into the specified `Decodable` type.
     
     This is a convenience method equivalent to calling ``response()`` followed by ``Response/asType(_:)``.
     
     - Parameter type: The `Decodable` type to decode the response body into. Can often be inferred from context.
     - Returns: A decoded instance of `T`.
     - Throws: Any error from ``response()``, or a `DecodingError` if decoding fails.
     */
    public func response<T: Decodable>(as type: T.Type = T.self) async throws -> T {
        let data = try await self.response().data
        return try JSONDecoder().decode(type, from: data)
    }
}
