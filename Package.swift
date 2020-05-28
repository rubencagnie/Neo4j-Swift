// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Theo",
	platforms: [
	        .macOS(.v10_14),
	        .iOS(.v12),
	        .tvOS(.v12)
	    ],
    products: [
        .library(name: "Theo", targets: ["Theo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "PackStream",
            dependencies: []),
        .target(
            name: "Bolt",
            dependencies: [
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                "PackStream"
        ]),
        .target(
            name: "Theo",
            dependencies: ["Bolt"]),
        .testTarget(
            name: "TheoTests",
            dependencies: ["Theo"])
    ]
)
