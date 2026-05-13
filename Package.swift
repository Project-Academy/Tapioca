// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Tapioca",
    platforms: [
        .tvOS(.v18),
        .iOS("17.4"),
        .macOS(.v13),
        .macCatalyst(.v18)
    ],
    products: [
        // Tapioca — the REST framework. Consumers usually want this.
        // It re-exports Presto via `@_exported import Presto`, so
        // `import Tapioca` alone gives you HTTPMethod, ContentType,
        // Request/Response et al. transparently.
        .library(name: "Tapioca", targets: ["Tapioca"]),

        // Presto — the low-level HTTP primitives. Exposed as its own
        // product so anyone who wants one-off requests without the
        // Tapioca pre/post-process machinery can pull this in alone.
        .library(name: "Presto",  targets: ["Presto"]),
    ],
    targets: [
        .target(name: "Presto"),
        .target(name: "Tapioca", dependencies: ["Presto"]),
    ]
)
