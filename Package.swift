// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LSM303",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "LSM303",
            targets: ["LSM303"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
	.package(url: "https://github.com/Kaiede/SwiftyGPIO.git", from: "1.0.10")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "LSM303",
            dependencies: ["SwiftyGPIO"]),
        .testTarget(
            name: "LSM303Tests",
            dependencies: ["LSM303"]),
    ]
)
