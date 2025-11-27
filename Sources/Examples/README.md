# NetworkMonitor 示例代码

> 完整的示例代码集合，帮助您快速上手 NetworkMonitor

**文档版本**: 1.0  
**最后更新**: 2025-11-27

---

## 📚 目录

- [SwiftUI 示例](#swiftui-示例)
- [UIKit 示例](#uikit-示例)
- [高级用例示例](#高级用例示例)
- [如何运行示例](#如何运行示例)

---

## 🎨 SwiftUI 示例

### 1. NetworkStatusView.swift

**功能**: 实时显示网络连接状态、类型和质量

**核心技术**:
- `@StateObject` 管理 NetworkMonitor 生命周期
- `@Published` 属性实现响应式更新
- Combine 订阅网络变化

**适用场景**:
- 应用中需要显示网络状态的地方
- 设置页面的网络信息展示
- 调试工具

**使用方法**:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NetworkStatusView()
    }
}
```

**效果**:
- 显示网络状态图标（WiFi、蜂窝网络等）
- 显示连接类型和网络质量
- 显示是否昂贵/受限网络
- 提供网络建议信息

---

### 2. AdaptiveContentView.swift

**功能**: 根据网络质量自动调整内容加载策略

**核心技术**:
- 网络质量评估
- 动态内容质量调整
- 离线模式处理

**适用场景**:
- 图片/视频内容展示
- 新闻/社交媒体应用
- 需要优化流量使用的场景

**使用方法**:
```swift
struct ContentView: View {
    var body: some View {
        AdaptiveContentView()
    }
}
```

**效果**:
- 网络质量优秀时加载高清内容
- 网络质量一般时加载标清内容
- 网络断开时显示离线提示
- 显示网络质量横幅

---

## 📱 UIKit 示例

### 1. NetworkStatusViewController.swift

**功能**: 使用代理模式监听网络状态变化并更新 UI

**核心技术**:
- 代理模式（NetworkMonitorDelegate）
- UIKit 动画效果
- Auto Layout 布局

**适用场景**:
- 传统 UIKit 项目
- 需要精细控制 UI 的场景
- 复杂的视图层级

**使用方法**:
```swift
let vc = NetworkStatusViewController()
navigationController?.pushViewController(vc, animated: true)
```

**效果**:
- 动画更新网络状态图标
- 显示详细的网络信息
- 提供网络建议

---

### 2. OfflineModeViewController.swift

**功能**: 演示如何优雅地处理离线模式

**核心技术**:
- 观察者模式（NetworkPathObserver）
- 离线横幅动画
- 自动重试机制

**适用场景**:
- 需要网络请求的页面
- 内容加载页面
- 需要离线提示的场景

**使用方法**:
```swift
let vc = OfflineModeViewController()
navigationController?.pushViewController(vc, animated: true)
```

**效果**:
- 网络断开时显示离线横幅（带动画）
- 自动暂停网络请求
- 网络恢复时自动重试
- 提供手动重试按钮

---

## 🚀 高级用例示例

### 1. MultiMonitorCoordinator.swift

**功能**: 同时监听 WiFi 和蜂窝网络，实现智能网络切换策略

**核心技术**:
- 多监听器协调
- 网络切换策略
- 代理模式

**适用场景**:
- 大文件下载（优先 WiFi）
- 视频流媒体（根据网络类型调整码率）
- 数据同步（WiFi 时全量同步，蜂窝网络时增量同步）

**使用方法**:
```swift
let coordinator = MultiMonitorCoordinator()
coordinator.delegate = self
coordinator.startMonitoring()
```

**效果**:
- 分别监听 WiFi 和蜂窝网络
- WiFi 可用时优先使用 WiFi
- 提供网络切换建议
- 支持自定义切换策略

---

### 2. AdaptiveQualityStrategy.swift

**功能**: 根据网络质量自动调整内容质量（图片、视频等）

**核心技术**:
- 网络质量评估
- 多级质量配置
- 自适应策略

**适用场景**:
- 图片加载（根据网络质量选择不同分辨率）
- 视频播放（根据网络质量调整码率）
- 内容预加载（根据网络质量决定是否预加载）

**使用方法**:
```swift
let strategy = AdaptiveQualityStrategy()
strategy.delegate = self
strategy.startMonitoring()
```

**效果**:
- 自动调整图片质量（缩略图/低清/标清/高清）
- 自动调整视频码率（360p/480p/720p/1080p）
- 智能预加载策略
- 支持自定义质量配置

---

### 3. AsyncAwaitExample.swift

**功能**: 演示如何使用 async/await 处理网络监听

**核心技术**:
- async/await 现代并发
- AsyncStream 异步序列
- 结构化并发

**适用场景**:
- 应用启动时等待网络
- 网络请求前确保网络可用
- 监听网络状态变化
- 实现重试机制

**使用方法**:
```swift
let example = AsyncAwaitExample()
Task {
    await example.run()
}
```

**示例包含**:
- 示例 1: 等待网络可用（带超时）
- 示例 2: 等待 WiFi 连接
- 示例 3: 使用 AsyncStream 监听网络变化
- 示例 4: 并发等待多个条件
- 示例 5: 带重试机制的网络请求

---

## 🛠️ 如何运行示例

### 方法 1: 在 Xcode Playground 中运行

1. 创建新的 Playground
2. 复制示例代码
3. 导入 NetworkMonitor 框架
4. 运行代码

### 方法 2: 在项目中集成

1. 将示例文件复制到项目中
2. 确保已安装 NetworkMonitor
3. 在需要的地方使用示例代码

### 方法 3: 运行示例应用

```bash
# 克隆仓库
git clone https://github.com/your-repo/NetworkMonitor.git

# 打开项目
cd NetworkMonitor
open NetworkMonitor.xcodeproj

# 选择示例 Target 运行
```

---

## 📝 示例代码统计

| 类别 | 文件数 | 代码行数 | 说明 |
|------|--------|---------|------|
| SwiftUI 示例 | 2 | ~400 | 响应式 UI 示例 |
| UIKit 示例 | 2 | ~500 | 传统 UI 示例 |
| 高级用例 | 3 | ~600 | 复杂场景示例 |
| **总计** | **7** | **~1500** | **完整示例集** |

---

## 💡 最佳实践

### 1. 选择合适的回调方式

- **简单场景**: 使用闭包回调
- **面向对象**: 使用代理模式
- **多对象监听**: 使用观察者模式
- **跨模块通信**: 使用 NotificationCenter
- **响应式编程**: 使用 Combine
- **现代并发**: 使用 async/await

### 2. 内存管理

```swift
// ✅ 使用 weak self 避免循环引用
monitor.pathUpdateHandler = { [weak self] path in
    self?.updateUI(with: path)
}

// ✅ 及时清理资源
deinit {
    monitor.stopMonitoring()
    monitor.removeObserver(self)
}
```

### 3. 线程安全

```swift
// ✅ 在主线程更新 UI
DispatchQueue.main.async {
    self.updateUI(with: path)
}
```

---

## 🤝 贡献示例

欢迎贡献新的示例代码！请遵循以下规范：

1. 添加详细的中文注释
2. 说明设计理念和使用场景
3. 提供完整的使用方法
4. 确保代码可以编译运行

---

## 📞 支持

如有问题，请：
- 查看 [完整文档](../README.md)
- 创建 [GitHub Issue](https://github.com/your-repo/NetworkMonitor/issues)

---

**Happy Coding! 🎉**

