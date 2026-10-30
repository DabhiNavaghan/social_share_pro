// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "social_share_pro",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "social-share-pro", targets: ["social_share_pro"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "social_share_pro",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
