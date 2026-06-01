// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "HEImageEditor",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "HEImagePackage", targets: ["HECommon", "HEImageEditor", "HEImagePicker"]),
        .library(name: "HEImageEditor", targets: ["HEImageEditor"]),
        .library(name: "HEImagePicker", targets: ["HEImagePicker"]),
        .library(name: "HECommon", targets: ["HECommon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.12.0")),
    ],
    targets: [
        .target(
            name: "HECommon",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher"),
            ]
        ),
        .target(
            name: "HEImageEditor",
            dependencies: ["HECommon"],
            exclude: [
                "Util/HEWeakProxy.h",
                "Util/HEWeakProxy.m"
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "HEImagePicker",
            dependencies: ["HECommon"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(name: "HEImageEditorTests",
                   dependencies: ["HEImageEditor", "HECommon"]),
        .testTarget(name: "HEImagePickerTests",
                   dependencies: ["HEImagePicker"])
    ]
)
