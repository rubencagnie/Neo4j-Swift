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
        .package(path: "./Bolt"),
        .package(path: "./PackStream")
    ],
    targets: [
        .target(
            name: "Theo",
            dependencies: [
                .product(name: "Bolt", package: "Bolt"),
                .product(name: "PackStream", package: "PackStream"),
            ]),
        .testTarget(
            name: "TheoTests",
            dependencies: ["Theo"])
    ]
)
