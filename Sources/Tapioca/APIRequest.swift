//
//  APIRequest.swift
//  Tapioca
//
//  Created by Sarfraz Basha on 13/11/2025.
//

import Foundation
import Presto

public protocol APIRequest: Sendable {
    associatedtype API: Tapioca<Self>
    
    //--------------------------------------
    // MARK: - VARIABLES -
    //--------------------------------------
    var urlRequest: URLRequest { get set }
    var httpMethod: HTTPMethod { get set }
    var baseURL: URL { get }
    
    //--------------------------------------
    // MARK: - STATE VARIABLES -
    //--------------------------------------
    var headers: [String: String] { get set }
    var accepts: ContentType { get set }
    var content: ContentType { get set }
    
    var params: [String: (any Sendable)] { get set }
    var paramTransformer: (@Sendable ([String: Any]) throws -> Data) { get set }
    
    //--------------------------------------
    // MARK: - INITIALISERS -
    //--------------------------------------
    init(url: URL, _ method: HTTPMethod?)
    
    //--------------------------------------
    // MARK: - MODIFIERS -
    //--------------------------------------
    func method(_ method: HTTPMethod) -> Self
    /**
     Sets a custom HTTP header field for the request.
     
     This modifier can be used to set common headers like `Authorization` or custom headers.
     The header is stored internally and applied to the `urlRequest` when `build()` is called.
     
     - Parameters:
       - value: The value for the HTTP header (e.g., a bearer token, or 'Keep-Alive').
       - headerKey: The name of the header field.
     - Returns: A new ``Request`` instance with the updated header.
     */
    func setHeader(key headerKey: String, value: String) -> Self
    /**
     Sets the parameters to be used in the request.
     
     For `.GET` requests, these parameters become URL query items.
     For `.POST`, `.PUT`, or `.DELETE` requests, these parameters become the HTTP body (e.g., JSON payload).
     - Parameter dict: A dictionary of parameters.
     - Returns: A new ``Request`` instance with updated parameters.
     */
    func params(_ dict: [String: (any Sendable)]) -> Self
    
    //--------------------------------------
    // MARK: - BUILDER -
    //--------------------------------------
    func build() throws -> Self
    
    //--------------------------------------
    // MARK: - RESPONSES -
    //--------------------------------------
    @MainActor
    func response() async throws -> Response
    func response<T: Decodable>(as type: T.Type) async throws -> T
}


extension APIRequest {
    public func method(_ method: HTTPMethod) -> Self {
        var request = self
        request.httpMethod = method
        return request
    }
    public func setHeader(key headerKey: String, value: String) -> Self {
        var request = self
        request.headers[headerKey] = value
        return request
    }
    public func params(_ dict: [String: (any Sendable)]) -> Self {
        var request = self
        for (key, value) in dict {
            request.params[key] = value
        }
        return request
    }
    
    public func build() throws -> Self {
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
            // Parse Parameters according to contentType.
            switch updated.content {
            case .JSON:
                urlReq.httpBody = try updated.paramTransformer(params)
            case .Form:
                urlReq.formatForm(params)
            default: break
            }
        }
        updated.urlRequest = urlReq
        return updated
    }
    
    @MainActor
    public func response() async throws -> Response {
        try await API.response(for: self.build())
    }
    public func response<T: Decodable>(as type: T.Type = T.self) async throws -> T {
        let data = try await self.response().data
        return try JSONDecoder().decode(type, from: data)
    }
    
    /**
     Sets the content type for the request body.
     
     - Parameters:
       - type: The desired ``ContentType`` (e.g., `.JSON`).
       - headerKey: The name of the header field, defaulting to "Content-Type".
     - Returns: A new ``Request`` instance with updated content type.
     */
    public func content(type: ContentType, headerKey: String = "Content-Type") -> Self {
        var request = self
        request.content = type
        return request.setHeader(key: headerKey, value: type.rawValue)
    }
    /**
     Sets the 'Accept' header for the request, specifying the MIME type the client is willing to accept from the server.
     
     - Parameters:
       - type: The expected ``ContentType`` (e.g., `.JSON`) to receive from the server.
       - headerKey: The name of the header field, defaulting to "Accept".
     - Returns: A new ``Request`` instance with updated content type.
     */
    public func accepts(type: ContentType, headerKey: String = "Accept") -> Self {
        var request = self
        request.accepts = type
        return request.setHeader(key: headerKey, value: type.rawValue)
    }
    
    
    public var GET: Response {
        get async throws {
            let request = self.method(.GET)
            return try await request.response()
        }
    }
    public func GET() async throws -> Response {
        try await GET
    }
    public func GET<T: Decodable>(response type: T.Type = T.self) async throws -> T {
        let request = self.method(.GET)
        return try await request.response(as: type)
    }
    public var POST: Response {
        get async throws {
            let request = self.method(.POST)
            return try await request.response()
        }
    }
    public func POST<T: Decodable>(response type: T.Type = T.self) async throws -> T {
        let request = self.method(.POST)
        return try await request.response(as: type)
    }
    
}
