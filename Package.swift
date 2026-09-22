// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UTUVODrop",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "UTUVODrop", targets: ["UTUVODropApp"]),
        .library(name: "UTUVODropCore", targets: ["UTUVODropCore"]),
    ],
    targets: [
        .target(
            name: "UTUVODropCore",
            path: "Sources/UTUVODropCore"
        ),
        .testTarget(
            name: "UTUVODropCoreTests",
            dependencies: ["UTUVODropCore"],
            path: "Tests/UTUVODropCoreTests"
        ),
        .executableTarget(
            name: "UTUVODropApp",
            dependencies: ["UTUVODropCore"],
            path: "Sources/UTUVODropApp",
            resources: [.copy("Assets")]
        ),
        .testTarget(
            name: "UTUVODropAppTests",
            dependencies: ["UTUVODropApp"],
            path: "Tests/UTUVODropAppTests"
        ),
    ]
)
