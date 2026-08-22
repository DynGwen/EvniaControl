// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EvniaControl",
    platforms: [.macOS("14.2")],
    products: [
        .executable(
            name: "EvniaControl",
            targets: ["EvniaControl"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/CJStanfield/CoreAudioTapKit.git",
            revision: "91538c3f432752c6bb7bb0efbfe4c26a67d19a5b"
        )
    ],
    targets: [
        .executableTarget(
            name: "EvniaControl",
            dependencies: [
                .product(
                    name: "CoreAudioTapKit",
                    package: "CoreAudioTapKit"
                )
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
