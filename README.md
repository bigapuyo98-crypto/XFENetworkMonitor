# XFENetworkMonitor

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2013.0%2B%20%7C%20macOS%2010.15%2B-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/CocoaPods-compatible-brightgreen.svg" alt="CocoaPods">
  <img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg" alt="SPM">
</p>

强大的 iOS/macOS 网络监控框架，支持实时网络状态监听、智能质量评估和多种回调机制。

## ✨ 主要特性

- 🌐 **实时网络监听**：支持 WiFi、蜂窝网络、有线网络等多种连接类型
- 📊 **智能质量评估**：多维度评估网络质量（优秀、良好、一般、差）
- 🔄 **6 种回调机制**：闭包、代理、观察者、通知、Combine、AsyncStream
- ⚡️ **Swift 并发支持**：完整的 async/await 支持
- 🔒 **线程安全设计**：所有 API 都是线程安全的
- 🔋 **低功耗优化**：智能管理系统资源
- 📱 **易于集成**：支持 CocoaPods 和 Swift Package Manager
- 📖 **完善文档**：详细的 API 文档和示例代码

## 📋 系统要求

- iOS 13.0+ / macOS 10.15+
- Xcode 15.0+
- Swift 5.9+

## 📦 安装

### Swift Package Manager

#### 方式 1：通过 Xcode

1. 打开你的项目
2. 选择 `File` > `Add Package Dependencies...`
3. 输入仓库 URL：
   ```
   git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git
   ```
4. 选择版本规则（推荐 `Up to Next Major Version`，输入 `1.0.0`）
5. 点击 `Add Package`

#### 方式 2：通过 Package.swift

在你的 `Package.swift` 文件中添加：

```swift
dependencies: [
    .package(
        url: "git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git",
        from: "1.0.0"
    )
]
```

然后在 target 中添加依赖：

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["XFENetworkMonitor"]
    )
]
```

## 🚀 快速开始

### 基础用法

```swift
import XFENetworkMonitor

// 1. 启动监听
NetworkMonitor.shared.startMonitoring()

// 2. 使用闭包回调
NetworkMonitor.shared.pathUpdateHandler = { path in
    print("网络状态: \(path.connectionType.displayName)")
    print("网络质量: \(path.quality.displayName)")
    print("是否可用: \(path.isNetworkAvailable)")
}

// 3. 停止监听（可选）
// NetworkMonitor.shared.stopMonitoring()
```

### SwiftUI 集成

```swift
import SwiftUI
import Combine
import XFENetworkMonitor

class NetworkViewModel: ObservableObject {
    @Published var isOnline: Bool = false
    @Published var connectionType: ConnectionType = .unavailable
    @Published var networkQuality: NetworkQuality = .poor
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 使用 Combine 订阅网络变化
        NetworkMonitor.shared.pathPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.isOnline = path.isNetworkAvailable
                self?.connectionType = path.connectionType
                self?.networkQuality = path.quality
            }
            .store(in: &cancellables)
        
        NetworkMonitor.shared.startMonitoring()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = NetworkViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.isOnline ? "在线" : "离线")
            Text("连接类型: \(viewModel.connectionType.displayName)")
            Text("网络质量: \(viewModel.networkQuality.displayName)")
        }
    }
}
```

### async/await 用法

```swift
import XFENetworkMonitor

// 等待网络可用
Task {
    do {
        try await NetworkMonitor.shared.waitForNetwork(timeout: 30.0)
        print("✅ 网络已可用")
    } catch {
        print("❌ 等待超时")
    }
}

// 等待 WiFi 连接
Task {
    do {
        try await NetworkMonitor.shared.waitForWiFi(timeout: 60.0)
        print("✅ WiFi 已连接")
    } catch {
        print("❌ 等待超时")
    }
}

// 监听网络变化流
Task {
    for await path in NetworkMonitor.shared.pathUpdates {
        print("网络变化: \(path.connectionType.displayName)")
        
        if path.quality >= .good {
            print("✅ 网络质量良好，可以开始下载")
            break
        }
    }
}
```

### 代理模式

```swift
import XFENetworkMonitor

class MyViewController: UIViewController, NetworkMonitorDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NetworkMonitor.shared.delegate = self
        NetworkMonitor.shared.startMonitoring()
    }
    
    func networkMonitor(_ monitor: NetworkMonitor, didUpdatePath path: NetworkPath) {
        print("网络状态更新: \(path.connectionType.displayName)")
    }
    
    func networkMonitor(_ monitor: NetworkMonitor, didEncounterError error: Error) {
        print("监听错误: \(error.localizedDescription)")
    }
}
```

### 观察者模式

```swift
import XFENetworkMonitor

class MyObserver: NetworkPathObserver {
    func networkPathDidChange(_ path: NetworkPath) {
        print("网络变化: \(path.connectionType.displayName)")
    }
}

let observer = MyObserver()
NetworkMonitor.shared.addObserver(observer)
NetworkMonitor.shared.startMonitoring()

// 移除观察者
// NetworkMonitor.shared.removeObserver(observer)
```

### 通知中心

```swift
import XFENetworkMonitor

// 监听网络状态变化
NotificationCenter.default.addObserver(
    forName: .networkPathDidChange,
    object: nil,
    queue: .main
) { notification in
    if let path = notification.userInfo?[NetworkNotificationKeys.networkPath] as? NetworkPath {
        print("网络变化: \(path.connectionType.displayName)")
    }
}

// 监听网络可用性变化
NotificationCenter.default.addObserver(
    forName: .networkDidBecomeAvailable,
    object: nil,
    queue: .main
) { _ in
    print("✅ 网络已可用")
}

NotificationCenter.default.addObserver(
    forName: .networkDidBecomeUnavailable,
    object: nil,
    queue: .main
) { _ in
    print("❌ 网络不可用")
}
```

## 📚 核心 API

### NetworkMonitor

主要的网络监控类，提供单例访问：

```swift
// 单例实例
NetworkMonitor.shared

// 启动/停止监听
func startMonitoring()
func stopMonitoring()

// 当前状态
var currentPath: NetworkPath?
var isMonitoring: Bool

// 便捷属性
var isNetworkAvailable: Bool
var connectionType: ConnectionType
var networkQuality: NetworkQuality
```

### NetworkPath

网络路径信息：

```swift
struct NetworkPath {
    var isNetworkAvailable: Bool        // 网络是否可用
    var connectionType: ConnectionType  // 连接类型
    var quality: NetworkQuality         // 网络质量
    var isExpensive: Bool               // 是否昂贵（蜂窝网络）
    var isConstrained: Bool             // 是否受限（低数据模式）
    var supportsDNS: Bool               // 是否支持 DNS
    var supportsIPv4: Bool              // 是否支持 IPv4
    var supportsIPv6: Bool              // 是否支持 IPv6
}
```

### ConnectionType

连接类型枚举：

```swift
enum ConnectionType: String, CaseIterable, Codable {
    case wifi           // WiFi
    case cellular       // 蜂窝网络
    case wiredEthernet  // 有线网络
    case loopback       // 回环
    case other          // 其他
    case unavailable    // 不可用
}
```

### NetworkQuality

网络质量枚举：

```swift
enum NetworkQuality: String, CaseIterable, Codable, Comparable {
    case poor       // 差（0-39 分）
    case fair       // 一般（40-69 分）
    case good       // 良好（70-89 分）
    case excellent  // 优秀（90-100 分）
}
```

## 🎯 使用场景

### 1. 自适应内容加载

```swift
NetworkMonitor.shared.pathUpdateHandler = { path in
    switch path.quality {
    case .excellent, .good:
        // 加载高清图片和视频
        loadHighQualityContent()
    case .fair:
        // 加载标清内容
        loadStandardQualityContent()
    case .poor:
        // 只加载文本
        loadTextOnlyContent()
    }
}
```

### 2. 离线模式切换

```swift
NetworkMonitor.shared.pathUpdateHandler = { path in
    if path.isNetworkAvailable {
        // 切换到在线模式
        switchToOnlineMode()
    } else {
        // 切换到离线模式
        switchToOfflineMode()
    }
}
```

### 3. 网络质量提示

```swift
NetworkMonitor.shared.pathUpdateHandler = { path in
    if path.isExpensive {
        showAlert("当前使用蜂窝网络，可能产生流量费用")
    }
    
    if path.isConstrained {
        showAlert("低数据模式已开启，建议减少数据使用")
    }
    
    if path.quality == .poor {
        showAlert("网络质量较差，建议稍后重试")
    }
}
```

## 🔧 高级用法

### 监听特定接口类型

```swift
// 只监听 WiFi
let wifiMonitor = NetworkMonitor.wifiMonitor
wifiMonitor.startMonitoring()

// 只监听蜂窝网络
let cellularMonitor = NetworkMonitor.cellularMonitor
cellularMonitor.startMonitoring()
```

### 网络质量评估

```swift
let path = NetworkMonitor.shared.currentPath
if let assessment = path?.qualityAssessment {
    print("总分: \(assessment.totalScore)")
    print("状态分: \(assessment.statusScore)")
    print("约束分: \(assessment.constraintScore)")
    print("成本分: \(assessment.costScore)")
    print("类型分: \(assessment.typeScore)")
}
```


## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

XFENetworkMonitor 使用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 👥 作者

XFE

## 🙏 致谢

感谢所有贡献者和使用者！

---

<p align="center">Made with by XFE </p>
