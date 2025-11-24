//
//  Tapioca.swift
//  Tapioca
//
//  Created by Sarfraz Basha on 12/11/2025.
//

import Foundation
@_exported import Presto

@MainActor
public protocol Tapioca<R> {
    associatedtype R: APIRequest
    
    static var baseURL: URL { get }
    
    /**
     A function that runs **immediately prior** to the request being fired.
     This is a good place to do any final modifications to the APIRequest.
     This is essentially a 'choke-point' for all calls made to this API.
     
     This method is best suited to commonalities across your requests to this API;
     for example, adding authentication here saves you from needing to manually authenticate each and every request.
     The same applies to, for example, setting the "Accept" or "Content-Type" headers.
     
     If no pre-processing to the request is required, the body of this function can simply be:
     ```swift
     static func preProcess(request: T) async throws -> T {
        return request
     }
     ```
     */
    static func preProcess(request: R) async throws -> R
    /**
     A function that runs **immediately after** receiving a URLResponse from the fired APIRequest.
     This is a good place to do any post-processing to your response before returning it to your app.
     This is essentially a 'choke-point' for all responses from this API.
     
     This method is a good place to carry out any common error-checking work that your API might return;
     for example, it may be useful to check for a "Retry-After" header in a 'failed' response, and forcing the request to re-fire
     after sleeping for the appropriate amount of time, instead of handling this error at every call site.
     
     If no post-processing to the response is required, the body of this function can simply be:
     ```swift
     static func postProcess(response: Response) async throws -> Response
        return response
     }
     ```
     */
    static func postProcess(response: Response, from request: R) async throws -> Response
}
extension Tapioca {

    @MainActor
    public static func response(for request: R) async throws -> Response {
        let req = try await preProcess(request: request)
        let urlReq = try req.build().urlRequest
        let urlResp = try await URLSession.shared.data(for: urlReq)
        
        let resp = Response(urlResp)
        let response = try await postProcess(response: resp, from: request)
        return response
    }
    public static func response<V: Decodable>(for req: R, as type: V.Type = V.self) async throws -> V {
        let response: Response = try await response(for: req)
        let data = response.data
        return try JSONDecoder().decode(V.self, from: data)
    }
    
}
