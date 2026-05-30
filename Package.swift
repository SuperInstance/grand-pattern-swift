// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GrandPattern",
    targets: [
        .target(name: "GrandPattern"),
        .testTarget(name: "GrandPatternTests", dependencies: ["GrandPattern"])
    ]
)
