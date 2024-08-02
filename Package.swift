// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "findsimulator",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "findsimulator",
            targets: ["findsimulator"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "1.5.0")
        )
    ],
    targets: [
        .executableTarget(
            name: "findsimulator",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "findsimulatorTests",
            dependencies: ["findsimulator"]
        )
    ]
)
