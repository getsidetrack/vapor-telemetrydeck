// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "vapor-telemetrydeck",
    platforms: [
       .macOS(.v10_15),
       .iOS(.v13)
    ],
    products: [
        .library(name: "TelemetryDeck", targets: ["TelemetryDeck"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "TelemetryDeck", dependencies: [
            .product(name: "Vapor", package: "vapor"),
        ]),
        .testTarget(name: "TelemetryDeckTests", dependencies: [
            .target(name: "TelemetryDeck"),
            .product(name: "XCTVapor", package: "vapor"),
        ]),
    ]
)
