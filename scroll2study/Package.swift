// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "scroll2study",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "scroll2study",
            targets: ["scroll2study"])
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.2.6"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.21.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "scroll2study",
            dependencies: [
                "OpenAI",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            ],
            resources: [
                .copy("Config.plist"),
                .copy(".env"),
            ]),
        .testTarget(
            name: "scroll2studyTests",
            dependencies: ["scroll2study"]
        ),
    ]
)
