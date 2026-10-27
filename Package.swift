// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PushKit",
    platforms: [.macOS(.v27)],
    dependencies: [
        .package(name: "swift-usb", path: "/Users/jae/Documents/random stuff/swift-usb"),
        .package(url: "https://github.com/stackotter/swift-image-formats.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "PushDisplayDriver",
            dependencies: [
                .product(name: "USB", package: "swift-usb"),
            ],
            swiftSettings: [
                .treatWarning("EmbeddedRestrictions", as: .error),
            ],
        ),
        .testTarget(
            name: "PushKitDisplayTest",
            dependencies: [
                .target(name: "PushDisplayDriver"),
                .product(name: "ImageFormats", package: "swift-image-formats"),
            ],
            resources: [
                .process("Resources")
            ],
        )

    ],
    swiftLanguageModes: [.v6]
)
