# NetworkMonitor 使用指南

> 完整的使用教程，从入门到精通

**文档版本**: 1.0  
**最后更新**: 2025-11-27  
**适用版本**: NetworkMonitor 1.0+

---

## 📚 目录

1. [快速入门](#1-快速入门)
2. [基础使用](#2-基础使用)
3. [6 种回调机制详解](#3-6-种回调机制详解)
4. [高级功能](#4-高级功能)
5. [最佳实践](#5-最佳实践)
6. [性能优化](#6-性能优化)
7. [故障排查](#7-故障排查)

---

## 1. 快速入门

### 1.1 安装

#### Swift Package Manager (推荐)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-repo/NetworkMonitor.git", from: "1.0.0")
]
```

#### CocoaPods

```ruby
pod 'NetworkMonitor'
```

### 1.2 第一个示例

```swift
import Reachability

// 1. 获取共享实例
let monitor = NetworkMonitor.shared

// 2. 设置回调
monitor.pathUpdateHandler = { path in
    print("网络状态: \(path.connectionType.displayName)")
}

// 3. 启动监听
monitor.startMonitoring()

// 4. 检查网络状态
if monitor.isNetworkAvailable {
    print("网络可用")
}
```

---

## 2. 基础使用

### 2.1 启动和停止监听

```swift
let monitor = NetworkMonitor.shared

// 启动监听
monitor.startMonitoring()

// 停止监听
monitor.stopMonitoring()

// 检查监听状态
if monitor.isMonitoring {
    print("监听器正在运行")
}
```

### 2.2 检查网络状态

```swift
// 检查网络是否可用
if monitor.isNetworkAvailable {
    performNetworkRequest()
}

// 获取连接类型
switch monitor.connectionType {
case .wifi:
    print("WiFi 连接")
case .cellular:
    print("蜂窝网络")
case .wiredEthernet:
    print("有线网络")
case .unavailable:
    print("网络不可用")
default:
    print("其他连接类型")
}

// 获取网络质量
switch monitor.networkQuality {
case .poor:
    print("网络质量差")
case .fair:
    print("网络质量一般")
case .good:
    print("网络质量良好")
case .excellent:
    print("网络质量优秀")
}
```

### 2.3 检查网络特性

```swift
// 检查是否为昂贵网络（蜂窝网络）
if monitor.isExpensiveNetwork {
    print("当前使用蜂窝网络，可能产生流量费用")
    pauseLargeDownloads()
}

// 检查是否为受限网络（低数据模式）
if monitor.isConstrainedNetwork {
    print("用户开启了低数据模式")
    reducedImageQuality()
}

// 检查是否为 WiFi 连接
if monitor.isWiFiConnection {
    print("WiFi 连接，可以进行大文件传输")
}

// 检查是否为蜂窝网络
if monitor.isCellularConnection {
    print("蜂窝网络，建议降低数据使用")
}
```

---

## 3. 6 种回调机制详解

### 3.1 闭包回调（最简单）

**适用场景**: 简单的网络状态监听

**优点**:
- 代码简洁
- 易于理解
- 适合单一监听点

**示例**:

```swift
let monitor = NetworkMonitor.shared

// 设置路径更新回调
monitor.pathUpdateHandler = { path in
    print("网络变化: \(path.connectionType)")
    updateUI(with: path)
}

// 设置错误回调
monitor.errorHandler = { error in
    print("错误: \(error.localizedDescription)")
}

monitor.startMonitoring()
```

**注意事项**:
- 必须使用 `[weak self]` 避免循环引用
- 回调在主线程执行

```swift
monitor.pathUpdateHandler = { [weak self] path in
    self?.updateUI(with: path)
}
```

---

### 3.2 代理模式（面向对象）

**适用场景**: 需要多个回调方法的场景

**优点**:
- 符合 iOS 开发习惯
- 支持多个回调方法
- 类型安全

**示例**:

```swift
class NetworkViewController: UIViewController, NetworkMonitorDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        NetworkMonitor.shared.delegate = self
        NetworkMonitor.shared.startMonitoring()
    }
    
    // 网络路径更新
    func networkMonitor(_ monitor: NetworkMonitoring, didUpdatePath path: NetworkPath) {
        updateUI(with: path)
    }
    
    // 网络变为可用
    func networkMonitor(_ monitor: NetworkMonitoring, didBecomeAvailable path: NetworkPath) {
        showOnlineMessage()
    }
    
    // 网络变为不可用
    func networkMonitor(_ monitor: NetworkMonitoring, didBecomeUnavailable path: NetworkPath) {
        showOfflineMessage()
    }
    
    // 发生错误
    func networkMonitor(_ monitor: NetworkMonitoring, didEncounterError error: Error) {
        showError(error)
    }
}
```

**注意事项**:
- delegate 使用 weak 引用，无需担心循环引用
- 只能有一个代理对象

---

### 3.3 观察者模式（多对象监听）

**适用场景**: 多个对象需要监听网络状态

**优点**:
- 支持多个观察者
- 观察者自动释放（weak 引用）
- 解耦性好

**示例**:

```swift
class NetworkStatusView: UIView, NetworkPathObserver {
    func networkPathDidChange(_ path: NetworkPath) {
        updateStatusLabel(with: path)
    }
}

class DataSyncManager: NetworkPathObserver {
    func networkPathDidChange(_ path: NetworkPath) {
        if path.isNetworkAvailable {
            startSync()
        } else {
            pauseSync()
        }
    }
}

// 添加观察者
let statusView = NetworkStatusView()
let syncManager = DataSyncManager()

NetworkMonitor.shared.addObserver(statusView)
NetworkMonitor.shared.addObserver(syncManager)

// 移除观察者（可选，观察者释放时自动移除）
NetworkMonitor.shared.removeObserver(statusView)
```

**注意事项**:
- 观察者使用 weak 引用，释放时自动移除
- 适合多个独立模块监听网络状态

---

### 3.4 NotificationCenter（系统通知）

**适用场景**: 跨模块通信，松耦合

**优点**:
- 完全解耦
- 支持多个监听者
- 符合 iOS 开发习惯

**示例**:

```swift
// 添加观察者
NotificationCenter.default.addObserver(
    self,
    selector: #selector(networkDidChange),
    name: .networkPathDidChange,
    object: nil
)

@objc func networkDidChange(_ notification: Notification) {
    if let path = notification.userInfo?[NetworkNotificationKeys.path] as? NetworkPath {
        print("网络变化: \(path.connectionType)")
        updateUI(with: path)
    }
}

// 移除观察者
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

**可用的通知**:

```swift
// 网络路径变化
.networkPathDidChange

// 网络变为可用
.networkDidBecomeAvailable

// 网络变为不可用
.networkDidBecomeUnavailable

// 连接类型变化
.networkConnectionTypeDidChange

// 网络质量变化
.networkQualityDidChange

// 网络成本变化
.networkCostDidChange

// 网络约束变化
.networkConstraintsDidChange
```

---

### 3.5 Combine（响应式编程）

**适用场景**: 响应式编程，数据流处理

**优点**:
- 支持链式操作
- 易于组合和转换
- 自动内存管理

**示例**:

```swift
import Combine

class NetworkViewModel: ObservableObject {
    @Published var isOnline: Bool = false
    @Published var connectionType: ConnectionType = .unavailable
    @Published var networkQuality: NetworkQuality = .poor

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 订阅网络路径变化
        NetworkMonitor.shared.pathPublisher
            .map { $0.isNetworkAvailable }
            .assign(to: &$isOnline)

        NetworkMonitor.shared.pathPublisher
            .map { $0.connectionType }
            .assign(to: &$connectionType)

        NetworkMonitor.shared.pathPublisher
            .map { $0.quality }
            .assign(to: &$networkQuality)

        // 高级用法：过滤和转换
        NetworkMonitor.shared.pathPublisher
            .filter { $0.isNetworkAvailable }
            .map { $0.connectionType }
            .removeDuplicates()
            .sink { connectionType in
                print("连接类型变化: \(connectionType)")
            }
            .store(in: &cancellables)
    }
}
```

**SwiftUI 集成**:

```swift
struct NetworkStatusView: View {
    @StateObject private var viewModel = NetworkViewModel()

    var body: some View {
        VStack {
            if viewModel.isOnline {
                Text("在线")
                    .foregroundColor(.green)
            } else {
                Text("离线")
                    .foregroundColor(.red)
            }

            Text("连接类型: \(viewModel.connectionType.displayName)")
            Text("网络质量: \(viewModel.networkQuality.displayName)")
        }
    }
}
```

---

### 3.6 Async/Await（现代并发）

**适用场景**: 异步等待网络可用，现代并发编程

**优点**:
- 代码清晰易读
- 避免回调地狱
- 支持超时控制

**示例 1: 等待网络可用**

```swift
Task {
    do {
        // 等待网络可用（30 秒超时）
        try await NetworkMonitor.shared.waitForNetwork(timeout: 30.0)

        // 网络可用后执行
        await performNetworkRequest()

    } catch NetworkMonitorError.timeout {
        print("等待网络超时")
        showOfflineMessage()

    } catch {
        print("错误: \(error)")
    }
}
```

**示例 2: 监听网络变化**

```swift
Task {
    for await path in NetworkMonitor.shared.pathUpdates {
        print("网络变化: \(path.connectionType)")

        // 等待网络质量达到良好
        if path.quality >= .good {
            print("网络质量良好，开始下载")
            break
        }
    }
}
```

**示例 3: 等待特定网络类型**

```swift
Task {
    // 等待 WiFi 连接
    try await NetworkMonitor.shared.waitForWiFi(timeout: 60.0)
    startLargeFileDownload()
}
```

---

## 4. 高级功能

### 4.1 网络质量评估

NetworkMonitor 提供 4 级网络质量评估系统：

```swift
public enum NetworkQuality: Int, Comparable {
    case poor = 0       // 网络不可用或质量极差
    case fair = 1       // 网络质量一般（受限或昂贵）
    case good = 2       // 网络质量良好（蜂窝网络）
    case excellent = 3  // 网络质量优秀（WiFi）
}
```

**评估维度**:
1. **网络可用性** - 最高优先级
2. **用户数据使用偏好** - 低数据模式
3. **网络成本** - 蜂窝网络 vs WiFi
4. **连接稳定性和速度**

**使用示例**:

```swift
let monitor = NetworkMonitor.shared

// 根据网络质量调整应用行为
switch monitor.networkQuality {
case .poor:
    // 网络质量差 - 启用离线模式
    enableOfflineMode()
    pauseNonEssentialRequests()
    showOfflineMessage()

case .fair:
    // 网络质量一般 - 启用数据节省模式
    enableDataSavingMode()
    reducedImageQuality = .low
    disableAutoPlay()
    pauseBackgroundSync()

case .good:
    // 网络质量良好 - 正常使用
    normalOperation()
    reducedImageQuality = .medium
    enableAutoPlay()

case .excellent:
    // 网络质量优秀 - 无限制使用
    enableHighQualityMode()
    reducedImageQuality = .high
    enableHDVideo()
    enableBackgroundSync()
}
```

