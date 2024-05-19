// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.\

import PackageDescription

let package = Package(
    name: "AiAPI",
    platforms: [
       .macOS(.v12)  // Set this to macOS 12 or newer
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AiAPI",
            targets: ["AiAPI"]),
    ],
    dependencies: [
        // Define the dependency on SwiftLint from the GitHub repository.
        .package(url: "https://github.com/realm/SwiftLint", branch: "main"),
        // Define the dependency on Callable from the GitHub repository.
        .package(url: "https://github.com/ElevatedUnderdogs/Callable.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AiAPI",
            dependencies: ["Callable"],  // Add "Callable" to the dependencies of the AiAPI target
            plugins: [
                // Use the SwiftLint plugin for this target.
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")
            ]),
        .testTarget(
            name: "AiAPITests",
            dependencies: ["AiAPI"]),
    ]
)

