// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "HEImageEditor",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HEImageEditor",
            targets: ["HEImageEditor"]),
        .library(
            name: "HEImagePicker",
            targets: ["HEImagePicker"]),
        .library(
            name: "HECommon",
            targets: ["HECommon"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "HECommon"
        ),
        .target(
            name: "HEImageEditor",
            dependencies: ["HECommon"],
//            path: "Sources",
            exclude: [
                "Util/HEWeakProxy.h",
                "Util/HEWeakProxy.m"
            ],
//            sources: ["HEImageEditor"],
            resources: [
                .process("Resources"),
//                .process("Resources/Assets.xcassets"),
            ]
        ),
        .target(
            name: "HEImagePicker",
            dependencies: ["HECommon"],
//            path: "Sources",
//            sources: ["HEImagePicker"],
            resources: [
                .process("Resources"),
//                .process("Resources/HEImagePickerLocalizable.strings"),
//                .process("Resources/Assets.xcassets"),
            ]
        ),
        .testTarget(name: "HEImageEditorTests",
                   dependencies: ["HEImageEditor"]),
        .testTarget(name: "HEImagePickerTests",
                   dependencies: ["HEImagePicker"])
    ]
)
