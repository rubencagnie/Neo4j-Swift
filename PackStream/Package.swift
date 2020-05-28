// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "PackStream",
	platforms: [
	        .macOS(.v10_14),
	        .iOS(.v12),
	        .tvOS(.v12)
	    ],
    products: [
        .library(name: "PackStream", targets: ["PackStream"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PackStream",
            dependencies: [])
    ]
)
