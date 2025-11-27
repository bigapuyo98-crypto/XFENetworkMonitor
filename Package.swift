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
    dependencies: [],
    
    // 目标定义
    targets: [
        // 主要库目标
        .target(
            name: "XFENetworkMonitor",
            dependencies: [],
            path: "Sources/NetworkMonitor",
            sources: [
                "Core/",
                "Models/"
            ],
            publicHeadersPath: nil,
            cSettings: nil,
            cxxSettings: nil,
            swiftSettings: [
                // Swift 编译器设置
                // Why: 启用 Swift 6 即将到来的特性，提前适配未来版本
                // 好处：确保代码在 Swift 6 正式发布时无需大量修改
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
                // 权衡：移除 unsafeFlags，因为 SPM 不允许带有 unsafeFlags 的包被作为依赖使用
                // StrictConcurrency 已涵盖 actor 数据竞争检查功能
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Network"),
                .linkedFramework("Combine", .when(platforms: [.iOS, .macOS]))
            ]
        ),
        
    ],

    // Swift 语言版本
    swiftLanguageVersions: [.v5]
)
