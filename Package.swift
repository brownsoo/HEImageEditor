// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "HEImageEditor",
    defaultLocalization: "ko",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HEImageEditor",
            targets: ["HEImageEditor", "HEImagePicker"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "HECommon",
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
                .process("Resources/HEImageEditorLocalizable.strings"),
                .process("Resources/Assets.xcassets"),
            ]
        ),
        .target(
            name: "HEImagePicker",
            dependencies: ["HECommon"],
//            path: "Sources",
//            sources: ["HEImagePicker"],
            resources: [
                .process("Resources/HEImagePickerLocalizable.strings"),
                .process("Resources/Assets.xcassets"),
            ]
        )
    ]
)
