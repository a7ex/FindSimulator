// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "findsimulator",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(
            name: "findsimulator",
            targets: ["findsimulator"]
        )
    ],
    dependencies: [
        .package(
            name: "swift-argument-parser",
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMajor(from: "0.4.3")
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
        )
    ]
)
