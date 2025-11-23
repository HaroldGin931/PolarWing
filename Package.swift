// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Polarwing",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/tesseract-one/Blake2.swift.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "Polarwing",
            dependencies: [
                .product(name: "Blake2", package: "Blake2.swift")
            ]
        )
    ]
)
