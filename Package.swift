// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "UltimateSoccerManager", platforms: [.macOS(.v14)], products: [.executable(name: "USM98", targets: ["USMApp"])], targets: [.target(name: "USMCore"), .executableTarget(name: "USMApp", dependencies: ["USMCore"], resources: [.copy("Resources")]), .executableTarget(name: "USMVerify", dependencies: ["USMCore"], path: "Tests/USMCoreTests")])
