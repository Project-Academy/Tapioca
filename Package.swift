// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tapioca",
    platforms: [
        .tvOS   (.v18),
        .iOS    ("17.4"),
        .macOS  (.v13),
        .macCatalyst(.v18)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Tapioca",
            targets: ["Tapioca"]
        ),
    ],
    dependencies: [
        .Presto
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Tapioca",
            dependencies: [
                .Presto
            ]
        ),

    ]
)

extension String {
    static let Presto = "https://github.com/Project-Academy/Presto"
}
extension Package.Dependency {
    static var Presto: Package.Dependency { .package(url: .Presto, branch: "main") }
}
extension Target.Dependency {
    static var Presto: Target.Dependency { .product(name: "Presto", package: "Presto") }
}
