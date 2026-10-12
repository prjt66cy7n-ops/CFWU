// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourFarmWithUnicornsCore",
    products: [.library(name: "YourFarmWithUnicorns", targets: ["YourFarmWithUnicorns"])],
    targets: [
        .target(name: "YourFarmWithUnicorns", path: "YourFarmWithUnicorns",
                exclude: ["Assets.xcassets", "PrivacyInfo.xcprivacy", "Resources", "FarmController.swift", "FarmScene.swift", "FarmViews.swift",
                          "GameArt.swift", "GameAudio.swift", "HorseNode.swift", "RidingScene.swift", "RidingViews.swift",
                          "StableViews.swift", "TaskScene.swift", "TaskViews.swift", "FlightScene.swift", "YourFarmWithUnicornsApp.swift"],
                sources: ["GameModel.swift", "HorseCatalog.swift", "RidingModel.swift", "GameplayModel.swift"]),
        .testTarget(name: "YourFarmWithUnicornsTests", dependencies: ["YourFarmWithUnicorns"], path: "YourFarmWithUnicornsTests")
    ]
)
