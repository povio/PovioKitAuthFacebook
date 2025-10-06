// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PovioKitAuthFacebook",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    .library(name: "PovioKitAuthFacebook", targets: ["PovioKitAuthFacebook"])
  ],
  dependencies: [
    .package(url: "https://github.com/facebook/facebook-ios-sdk", .upToNextMajor(from: "18.0.0")),
    .package(url: "https://github.com/povio/PovioKitAuth", branch: "release/3.0.0")
  ],
  targets: [
    .target(
      name: "PovioKitAuthFacebook",
      dependencies: [
        .product(name: "PovioKitAuthCore", package: "PovioKitAuth"),
        .product(name: "FacebookLogin", package: "facebook-ios-sdk")
      ],
      path: "Sources",
      resources: [.copy("../Resources/PrivacyInfo.xcprivacy")]
    )
  ]
)
