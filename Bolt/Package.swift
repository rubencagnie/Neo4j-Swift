// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Bolt",
	platforms: [
	        .macOS(.v10_14),
	        .iOS(.v12),
	        .tvOS(.v12)
	    ],
    products: [
        .library(name: "Bolt", targets: ["Bolt"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.1.1"),
        .package(path: "../PackStream")
    ],
    targets: [
        .target(
            name: "Bolt",
            dependencies: [
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
            .product(name: "PackStream", package: "PackStream"),
            ]),
    ]
)
