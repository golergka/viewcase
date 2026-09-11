// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "Viewcase",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .library(name: "Viewcase", targets: ["Viewcase"]),
    .executable(name: "ViewcaseExample", targets: ["ViewcaseExample"]),
  ],
  targets: [
    .target(name: "Viewcase"),
    .executableTarget(name: "ViewcaseExample", dependencies: ["Viewcase"]),
  ])
