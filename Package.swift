// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sleeper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "sleeper", targets: ["sleeper"])
    ],
    targets: [
        .executableTarget(
            name: "sleeper",
            path: "sleeper",
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content"),
                .copy("sleeper.entitlements")
            ]
        )
    ]
)