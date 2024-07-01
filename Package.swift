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
            targets: ["HEImageEditor"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "HEImageEditor",
            //path: "Sources",
            exclude: [
                "../Info.plist",
                "Util/HEWeakProxy.h",
                "Util/HEWeakProxy.m"
            ],
            resources: [
                .process("Resources/HEImageEditor.bundle")
            ]),
        .target(
            name: "HEImagePicker"
        )
    ]
)
