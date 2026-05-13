//
//  DefaultRequest.swift
//  Tapioca
//
//  Generic `APIRequest` conformance that absorbs the ~30 lines of
//  boilerplate every kit (SlackKit, MerakiKit, et al.) used to
//  hand-roll. A kit just declares:
//
//      public typealias Request = DefaultRequest<MyAPI>
//
//      public struct MyAPI: Tapioca {
//          public typealias R = Request
//          ...
//      }
//
//  and any API-specific chainable modifiers live as constrained
//  extensions:
//
//      extension DefaultRequest where API == MyAPI {
//          public func myCustomModifier(...) -> Self { ... }
//      }
//
//  Source-compatible with kits that previously had their own
//  `Request` struct, since `Request` becomes a typealias to the
//  same shape.
//

import Foundation

public struct DefaultRequest<API: Tapioca>: APIRequest {

    public var urlRequest: URLRequest
    public var httpMethod: HTTPMethod
    public let baseURL: URL

    public var headers: [String: String] = [:]
    public var accepts: ContentType = .JSON
    public var content: ContentType = .JSON

    public var params: [String: (any Sendable)] = [:]
    public var paramTransformer: (@Sendable ([String: Any]) throws -> Data) = { params in
        try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
    }

    public init(url: URL, _ method: HTTPMethod? = nil) {
        baseURL = url
        urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = (method ?? .GET).rawValue
        httpMethod = method ?? .GET
    }
}
