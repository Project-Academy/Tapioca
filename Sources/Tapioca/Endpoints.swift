//
//  Endpoints.swift
//  Tapioca
//
//  Created by Sarfraz Basha on 13/11/2025.
//

import Foundation
import Presto

/**
 An Endpoints object is a section of an API.
 
 The recommended way to use this is to conform an enum to this protocol.
 This will make each case in your enum an Endpoint, and give it access to
 the Request object for free.
 */
@MainActor
public protocol Endpoints<API> {
    associatedtype API: Tapioca
    static var base: URL { get }
    var path: URL { get }
}
extension Endpoints where Self: RawRepresentable, RawValue == String {
    public var path: URL { Self.base.appending(path: rawValue, directoryHint: .notDirectory) }
}

extension Endpoints {
    public var GET:     API.R { .init(url: self.path, .GET) }
    public var PUT:     API.R { .init(url: self.path, .PUT) }
    public var POST:    API.R { .init(url: self.path, .POST) }
    public var DELETE:  API.R { .init(url: self.path, .DELETE) }
}


