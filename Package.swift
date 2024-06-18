// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "HEImageEditor",
    platforms: [.iOS(.v10)],
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
            path: "Sources",
            exclude: [
                "Info.plist",
                "General/HEWeakProxy.h",
                "General/HEWeakProxy.m"
            ],
            resources: [
                .process("HEImageEditor.bundle")
            ]),
    ]
)
