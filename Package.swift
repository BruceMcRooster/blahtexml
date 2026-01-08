// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Blahtex",
    products: [
        .library(
            name: "Blahtex",
            targets: ["Blahtex"],
        )
    ],
    dependencies: [
        .package(url: "https://github.com/BruceMcRooster/SwiftWStringCompat.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Blahtex",
            dependencies: [
                "blahtexcxx",
                .product(name: "WStringCompat", package: "SwiftWStringCompat")
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)],
        ),
        .target(
            name: "blahtexcxx",
            path: "Source/BlahtexCore",
            publicHeadersPath: ".",
            cxxSettings: [
                .disableWarning("tautological-constant-out-of-range-compare"),
                .disableWarning("switch"),
                .disableWarning("#warnings") // Known warnings in the code
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)],
        ),
        .testTarget(
            name: "BlahtexSwiftTests", 
            dependencies: ["Blahtex"], 
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ],
)
