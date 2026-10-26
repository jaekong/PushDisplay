// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PushDisplay",
    platforms: [.macOS(.v27)],
    dependencies: [
        .package(name: "swift-usb", path: "/Users/jae/Documents/random stuff/swift-usb"),
        .package(url: "https://github.com/stackotter/swift-image-formats.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "PushDisplay",
            dependencies: [
                .product(name: "USB", package: "swift-usb"),
            ],
            swiftSettings: [
                .treatWarning("EmbeddedRestrictions", as: .warning),
            ],
        ),
        .testTarget(
            name: "PushDisplayTest",
            dependencies: [
                .target(name: "PushDisplay"),
                .product(name: "ImageFormats", package: "swift-image-formats"),
            ],
            resources: [
                .process("Resources")
            ],
        )

    ],
    swiftLanguageModes: [.v6]
)
