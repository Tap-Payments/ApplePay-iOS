// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ApplePay-iOS",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "ApplePay-iOS",
            targets: ["ApplePay-iOS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/TakeScoop/SwiftyRSA.git", from: "1.0.0"),
        .package(url: "https://github.com/Tap-Payments/SharedDataModels-iOS.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "ApplePay-iOS",
            dependencies: [
                "SwiftyRSA",
                "SharedDataModels-iOS",
            ]
        ),
        .testTarget(
            name: "ApplePayIOSTests",
            dependencies: ["ApplePay-iOS"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
