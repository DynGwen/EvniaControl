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
            from: "0.1.0"
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
