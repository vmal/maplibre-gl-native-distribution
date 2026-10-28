// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MapLibre Native",
    products: [
        .library(
            name: "MapLibre",
            targets: ["MapLibre"])
    ],
    dependencies: [
    ],    
    targets: [
        .binaryTarget(
            name: "MapLibre",
            url: "https://github.com/vmal/maplibre-gl-native-distribution/releases/download/6.25.0-clearprop.1/MapLibre.dynamic.xcframework.zip",
            checksum: "9fbb2adec0aa738b908a060ced707c0683ce7eea9487ec16b9a4c376878af88c")
    ]
)
