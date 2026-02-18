// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ProdiusTerm",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ProdiusTerm", targets: ["ProdiusTerm"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.4.1"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.7"),
    ],
    targets: [
        .executableTarget(
            name: "ProdiusTerm",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources"
        )
    ]
)
