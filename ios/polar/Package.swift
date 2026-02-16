// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "polar",
    platforms: [
      .iOS("14.0")
    ],
    products: [
        .library(name: "polar", targets: ["polar"])
    ],
    dependencies: [
        .package(url: "https://github.com/polarofficial/polar-ble-sdk.git", .exact("6.14.0"))
    ],
    targets: [
        .target(
            name: "polar",
            dependencies: [
                .product(name: "PolarBleSdk", package: "polar-ble-sdk")
            ],
            resources: [
                // TODO: If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
