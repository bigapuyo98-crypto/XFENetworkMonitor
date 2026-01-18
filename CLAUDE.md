[根目录](../CLAUDE.md) > **XFENetworkMonitor**

---

# XFENetworkMonitor 模块

> 最后更新：2026-01-16

## 模块职责

XFENetworkMonitor 是**网络监控模块**，提供网络状态监听、质量评估和变化追踪功能，支持 SwiftUI 和 UIKit。

**核心功能**：
- 网络状态监控（WiFi、蜂窝、离线）
- 网络质量评估（优秀、良好、一般、差）
- 网络变化追踪（连接类型变更、质量变更）
- 支持 Combine 和回调两种使用方式

---

## 入口与启动

### 基础监控（Combine）

```swift
import XFENetworkMonitor
import Combine

class MyViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let monitor = NetworkMonitor()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 订阅网络状态
        monitor.connectionTypePublisher
            .sink { connectionType in
                switch connectionType {
                case .wifi: print("WiFi 连接")
                case .cellular: print("蜂窝网络")
                case .wiredEthernet: print("有线网络")
                case .unknown: print("未知网络")
                }
            }
            .store(in: &cancellables)

        monitor.start()
    }

    deinit {
        monitor.stop()
    }
}
```

### 网络质量评估

```swift
let assessor = NetworkQualityAssessor()

assessor.qualityPublisher
    .sink { quality in
        switch quality {
        case .excellent: print("网络质量：优秀")
        case .good: print("网络质量：良好")
        case .fair: print("网络质量：一般")
        case .poor: print("网络质量：差")
        }
    }
    .store(in: &cancellables)

assessor.start()
```

### 回调方式（不使用 Combine）

```swift
let monitor = NetworkMonitor()

monitor.onConnectionChanged = { connectionType in
    print("网络连接变更: \(connectionType)")
}

monitor.onQualityChanged = { quality in
    print("网络质量变更: \(quality)")
}

monitor.start()
```

---

## 对外接口

### NetworkMonitor - 网络监控器

| 方法/属性 | 说明 |
|----------|------|
| `init()` | 初始化监控器 |
| `start()` / `stop()` | 启动/停止监控 |
| `connectionTypePublisher` | Combine Publisher（连接类型） |
| `isConnectedPublisher` | Combine Publisher（是否连接） |
| `onConnectionChanged` | 回调方式（连接变更） |
| `onQualityChanged` | 回调方式（质量变更） |
| `currentConnectionType` | 当前连接类型 |
| `isConnected` | 是否已连接 |

### NetworkQualityAssessor - 网络质量评估器

| 方法/属性 | 说明 |
|----------|------|
| `init()` | 初始化评估器 |
| `start()` / `stop()` | 启动/停止评估 |
| `qualityPublisher` | Combine Publisher（质量） |
| `currentQuality` | 当前质量 |

### 枚举类型

```swift
// 连接类型
public enum ConnectionType {
    case wifi
    case cellular
    case wiredEthernet
    case unknown
}

// 网络质量
public enum NetworkQuality {
    case excellent  // 优秀（延迟 < 50ms）
    case good       // 良好（延迟 50-150ms）
    case fair       // 一般（延迟 150-300ms）
    case poor       // 差（延迟 > 300ms）
}
```

---

## 关键依赖与配置

### 系统框架依赖

- **Foundation**：基础框架
- **Network**：NWPathMonitor 网络监控
- **Combine**：响应式编程

### 无外部依赖

XFENetworkMonitor 是一个**纯系统框架**模块，不依赖任何第三方库，可独立使用。

---

## 数据模型

### NetworkPath - 网络路径信息

```swift
public struct NetworkPath {
    public let connectionType: ConnectionType
    public let isExpensive: Bool  // 是否为计费网络（蜂窝）
    public let isConstrained: Bool  // 是否为受限网络（省电模式）
    public let availableInterfaces: [NWInterface.InterfaceType]
}
```

### NetworkChangeModels - 网络变化模型

```swift
public struct NetworkChange {
    public let fromType: ConnectionType
    public let toType: ConnectionType
    public let timestamp: Date
}

public struct QualityChange {
    public let fromQuality: NetworkQuality
    public let toQuality: NetworkQuality
    public let timestamp: Date
}
```

---

## 测试与质量

### 测试覆盖

- 基础监控测试
- 质量评估测试
- 变化追踪测试

### 示例工程

- **UIKit 示例**：`Sources/Examples/UIKit/`
- **SwiftUI 示例**：`Sources/Examples/SwiftUI/`
- **高级示例**：`Sources/Examples/Advanced/`（多监控器协调、自适应质量策略）

---

## 常见问题 (FAQ)

### Q1: 如何在 SwiftUI 中使用？

```swift
import SwiftUI
import XFENetworkMonitor

struct ContentView: View {
    @StateObject private var monitor = NetworkMonitor()

    var body: some View {
        VStack {
            Text("网络状态: \(monitor.currentConnectionType.description)")
                .onReceive(monitor.connectionTypePublisher) { connectionType in
                    print("网络变更: \(connectionType)")
                }
        }
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }
}
```

### Q2: 如何实现离线模式？

```swift
monitor.isConnectedPublisher
    .sink { isConnected in
        if isConnected {
            self.enableOnlineMode()
        } else {
            self.enableOfflineMode()
        }
    }
    .store(in: &cancellables)
```

### Q3: 如何根据网络质量调整行为？

```swift
assessor.qualityPublisher
    .sink { quality in
        switch quality {
        case .excellent, .good:
            self.loadHighQualityImages()
        case .fair:
            self.loadMediumQualityImages()
        case .poor:
            self.loadLowQualityImages()
        }
    }
    .store(in: &cancellables)
```

---

## 目录结构

```
XFENetworkMonitor/
├── Sources/
│   ├── NetworkMonitor/
│   │   ├── Core/                              # 核心组件 (5 文件)
│   │   │   ├── NetworkMonitor.swift           # 主监控器
│   │   │   ├── NetworkQualityAssessor.swift   # 质量评估器
│   │   │   ├── NetworkChangeTracker.swift     # 变化追踪器
│   │   │   ├── NetworkCallbacks.swift         # 回调定义
│   │   │   └── NetworkMonitorError.swift      # 错误定义
│   │   └── Models/                            # 数据模型 (5 文件)
│   │       ├── ConnectionType.swift           # 连接类型
│   │       ├── NetworkQuality.swift           # 网络质量
│   │       ├── NetworkPath.swift              # 网络路径
│   │       ├── NetworkChangeModels.swift      # 变化模型
│   │       └── QualityAssessmentModels.swift  # 评估模型
│   ├── Examples/                              # 示例工程
│   │   ├── UIKit/                             # UIKit 示例
│   │   ├── SwiftUI/                           # SwiftUI 示例
│   │   └── Advanced/                          # 高级示例
│   └── Resources/                             # 资源文件
└── README.md                                  # 项目说明
```

### 关键文件

| 文件 | 职责 |
|------|------|
| `NetworkMonitor/Core/NetworkMonitor.swift` | 网络监控主类 |
| `NetworkMonitor/Core/NetworkQualityAssessor.swift` | 网络质量评估 |
| `NetworkMonitor/Models/ConnectionType.swift` | 连接类型定义 |
| `NetworkMonitor/Models/NetworkQuality.swift` | 质量级别定义 |
| `Examples/UIKit/NetworkStatusViewController.swift` | UIKit 示例 |
| `Examples/SwiftUI/NetworkStatusView.swift` | SwiftUI 示例 |

---

## 变更记录 (Changelog)

### 2026-01-16
- 文档优化：从 376 行压缩到 300 行以内
- 压缩入口示例、API 接口、FAQ
- 简化目录结构

### 2025-12-26
- 初始化模块文档
- 完善公共 API 说明

---

**维护者**：xiao
**模块路径**：`/Users/dbuser/dbwork/classbro-redbook-ios/Modules/XFENetworkMonitor`
**相关文档**：[README.md](./README.md), [Examples/README.md](./Sources/Examples/README.md)
