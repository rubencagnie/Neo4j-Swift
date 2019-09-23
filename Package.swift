// swift-tools-version:5.0
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
        .package(url: "https://github.com/rubencagnie/Bolt-swift.git", from: "5.0.1")
    ],
    targets: [
        .target(
            name: "Theo",
            dependencies: ["Bolt"]),
        .testTarget(
            name: "TheoTests",
            dependencies: ["Theo"])
    ]
)
