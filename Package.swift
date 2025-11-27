// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XFENetworkMonitor",
    
    // 平台支持
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    
    // 产品定义
    products: [
        // 主要库产品
        .library(
            name: "XFENetworkMonitor",
            targets: ["XFENetworkMonitor"]
        ),
    ],
    
    // 依赖项（当前无外部依赖）
    dependencies: [
        // 示例：
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
    ],
    
    // 目标定义
    targets: [
        // 主要库目标
        .target(
            name: "XFENetworkMonitor",
            dependencies: [],
            path: "Sources/NetworkMonitor",
            exclude: [
                // 排除示例代码和文档
            ],
            sources: [
                "Core/",
                "Models/"
            ],
            publicHeadersPath: nil,
            cSettings: nil,
            cxxSettings: nil,
            swiftSettings: [
                // Swift 编译器设置
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-enable-actor-data-race-checks"], .when(configuration: .debug)),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Network"),
                .linkedFramework("Combine", .when(platforms: [.iOS, .macOS]))
            ]
        ),
        
        // 测试目标
        .testTarget(
            name: "XFENetworkMonitorTests",
            dependencies: ["XFENetworkMonitor"],
            path: "XFENetworkMonitorTests"
        ),
    ],
    
    // Swift 语言版本
    swiftLanguageVersions: [.v5]
)
