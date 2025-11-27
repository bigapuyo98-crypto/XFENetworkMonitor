# XFENetworkMonitor 架构分析总结

> 快速了解 XFENetworkMonitor 项目的核心架构和设计理念

---

## 📊 项目概览

**XFENetworkMonitor** 是一个功能完善、设计精良的 iOS/macOS 网络监控框架，基于 Apple 的 Network.framework 封装，提供了简单易用的 API 和强大的功能。

### 核心特性

- ✅ **6 种回调机制**：闭包、代理、观察者、NotificationCenter、Combine、AsyncStream
- ✅ **线程安全**：完善的线程安全机制，队列同步、NSLock 保护
- ✅ **内存安全**：weak 引用避免循环引用，自动内存管理
- ✅ **智能质量评估**：多维度网络质量评估和分析
- ✅ **变化追踪**：网络状态变化历史记录和统计分析
- ✅ **现代化支持**：Combine、async/await、AsyncStream
- ✅ **易于测试**：协议导向设计，易于 Mock

---

## 🏗️ 架构层次

```
┌─────────────────────────────────────────┐
│           应用层 (Application)           │
│  示例应用、SwiftUI/UIKit 示例、高级用例  │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│            核心层 (Core)                 │
│  NetworkMonitor、NetworkMonitoring       │
│  NetworkCallbacks、NetworkQualityAssessor│
│  NetworkChangeTracker                    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│           模型层 (Models)                │
│  NetworkPath、NetworkQuality             │
│  ConnectionType、QualityAssessmentModels │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│        系统框架层 (Frameworks)           │
│  Network.framework、Combine              │
│  Swift Concurrency                       │
└─────────────────────────────────────────┘
```

---

## 🔄 核心流程

### 1. 生命周期流程

```
应用启动
  ↓
获取 NetworkMonitor.shared
  ↓
设置回调 (pathUpdateHandler/delegate/observer)
  ↓
startMonitoring() - 启动监听
  ↓
[循环] 网络状态变化
  ↓ NWPathMonitor 回调
  ↓ 转换为 NetworkPath
  ↓ 检测状态变化
  ↓ 切换到主线程
  ↓ 分发到 6 种回调机制
  ↓
stopMonitoring() - 停止监听
  ↓
释放资源
```

### 2. 线程模型

```
系统网络队列 (NWPathMonitor)
        ↓
监听队列 (monitorQueue - utility QoS)
  - 接收系统回调
  - 转换数据模型
  - 检测状态变化
  - 管理内部状态
        ↓
主线程 (DispatchQueue.main)
  - 执行所有用户回调
  - 更新 UI
  - 发送通知
```

### 3. 数据流转

```
NWPath (系统) 
  → NetworkPath (封装)
  → 状态检测
  → 6 种回调机制
    1. 闭包回调 (pathUpdateHandler)
    2. 代理模式 (NetworkMonitorDelegate)
    3. 观察者模式 (NetworkPathObserver)
    4. 通知中心 (NotificationCenter)
    5. Combine (PassthroughSubject)
    6. AsyncStream (pathUpdates)
```

---

## 🎯 设计模式

| 模式 | 应用 | 优势 |
|------|------|------|
| **单例模式** | `NetworkMonitor.shared` | 全局唯一实例，避免资源浪费 |
| **观察者模式** | `NetworkPathObserver` | 一对多通知，松耦合 |
| **代理模式** | `NetworkMonitorDelegate` | 类型安全，面向对象 |
| **协议导向** | `NetworkMonitoring` | 依赖抽象，易于测试 |
| **工厂模式** | `monitor(for:)` | 灵活创建特定类型监听器 |
| **策略模式** | `NetworkQualityAssessor` | 多种质量评估策略 |

---

## 💡 核心组件

### NetworkMonitor - 核心监听器

**职责**：
- 封装 NWPathMonitor
- 管理监听生命周期
- 线程安全的状态管理
- 多种回调机制分发

**关键设计**：
- 单例模式 + 工厂方法
- 专用队列 (utility QoS)
- 队列同步确保线程安全
- weak 引用避免循环引用

### NetworkPath - 网络路径模型

**职责**：
- 封装网络连接状态
- 提供便捷的计算属性
- 支持序列化

**关键设计**：
- 值类型 (struct) 确保线程安全
- 不可变属性避免意外修改
- 支持 Codable

### NetworkQualityAssessor - 质量评估器

**职责**：
- 多维度评估网络质量
- 提供详细分析
- 生成优化建议

**评估维度**：
1. 网络状态 (statusScore)
2. 用户约束 (constraintScore)
3. 网络成本 (costScore)
4. 连接类型 (typeScore)
5. 协议支持 (protocolScore)

---

## 🔒 线程安全机制

### 1. 队列同步访问

```swift
public var currentPath: NetworkPath? {
    return monitorQueue.sync { _currentPath }
}
```

### 2. NSLock 保护

```swift
observersLock.lock()
defer { observersLock.unlock() }
observers.add(observer as AnyObject)
```

### 3. weak 引用

```swift
monitor.pathUpdateHandler = { [weak self] path in
    self?.updateUI(with: path)
}
```

---

## 📈 性能优化

- ✅ **QoS 选择**：使用 `.utility` 平衡性能和电量
- ✅ **状态检测**：避免重复通知，减少开销
- ✅ **环形缓冲**：限制历史记录大小
- ✅ **智能过滤**：过滤噪音数据
- ✅ **异步执行**：不阻塞调用线程
- ✅ **值类型**：减少引用计数开销

---

## 📚 完整文档

详细的架构分析请查看：
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 完整架构分析文档（1500+ 行）
  - 包含详细的流程图、序列图、状态图
  - 深入的代码实现分析
  - 性能优化策略
  - 最佳实践建议

其他文档：
- **[USER_GUIDE.md](Sources/docs/USER_GUIDE.md)** - 用户使用指南
- **[API_REFERENCE.md](Sources/docs/API_REFERENCE.md)** - API 参考文档
- **[Examples](Sources/Examples/)** - 示例代码

---

**Happy Coding! 🎉**

