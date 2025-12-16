# 🚀 XFENetworkMonitor 快速开始

本文档帮助你在 5 分钟内完成 XFENetworkMonitor 的发布和集成。

---

## 📦 发布到 CocoaPods 和 SPM

### 前提条件

- ✅ 已安装 CocoaPods：`pod --version`
- ✅ 已安装 Swift：`swift --version`
- ✅ 有 Git 仓库访问权限
- ✅ 已注册 CocoaPods Trunk 账号（首次发布需要）

### 快速发布步骤

#### 1️⃣ 验证配置（1 分钟）

```bash
# 运行验证脚本
./validate.sh
```

**预期输出**：
- ✅ 所有配置文件存在
- ✅ Podspec 验证通过
- ✅ Package.swift 验证通过
- ✅ Swift Package 构建成功

#### 2️⃣ 提交代码（1 分钟）

```bash
# 查看当前状态
git status

# 添加所有文件
git add .

# 提交更改
git commit -m "Release version 1.0.0

- 添加 CocoaPods 支持
- 添加 Swift Package Manager 支持
- 完善文档和示例
"

# 推送到远程仓库
git push origin main
```

#### 3️⃣ 创建 Release Tag（1 分钟）

```bash
# 创建 tag
git tag -a 1.0.0 -m "Release version 1.0.0

主要特性：
- 🌐 实时网络状态监听
- 📊 智能网络质量评估
- 🔄 6 种回调机制
- ⚡️ Swift 并发支持
- 🔒 线程安全设计
"

# 推送 tag
git push origin 1.0.0

# 验证 tag
git tag -l
```

#### 4️⃣ 发布到 CocoaPods（2 分钟）

```bash
# 首次发布需要注册（只需一次）
# pod trunk register your-email@example.com 'Your Name'

# 发布到 CocoaPods
pod trunk push XFENetworkMonitor.podspec --allow-warnings

# 验证发布成功
pod search XFENetworkMonitor
```

#### 5️⃣ 在 Git 平台创建 Release（可选）

**Aliyun Codeup**：
1. 访问：https://codeup.aliyun.com/68be51c2479007fe862e73cb/xtool/XFENetworkMonitor
2. 点击 "发布" → "新建发布"
3. 选择 tag：1.0.0
4. 填写发布说明
5. 点击 "创建发布"

---

## 🎯 在其他项目中使用

### 方式 1：CocoaPods（推荐用于 iOS 项目）

#### 步骤 1：创建 Podfile

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'XFENetworkMonitor', '~> 1.0'
end
```

#### 步骤 2：安装

```bash
pod install
open YourApp.xcworkspace
```

#### 步骤 3：使用

```swift
import XFENetworkMonitor

// 在 AppDelegate 中启动
NetworkMonitor.shared.pathUpdateHandler = { path in
    print("网络状态: \(path.connectionType.displayName)")
}
NetworkMonitor.shared.startMonitoring()
```

### 方式 2：Swift Package Manager（推荐用于跨平台项目）

#### 通过 Xcode UI

1. File → Add Package Dependencies...
2. 输入 URL：`git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git`
3. 选择版本：1.0.0
4. 点击 Add Package

#### 通过 Package.swift

```swift
dependencies: [
    .package(
        url: "git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git",
        from: "1.0.0"
    )
]
```

---

## 💡 基础使用示例

### 1. 闭包回调（最简单）

```swift
import XFENetworkMonitor

NetworkMonitor.shared.pathUpdateHandler = { path in
    if path.isNetworkAvailable {
        print("✅ 网络可用: \(path.connectionType.displayName)")
    } else {
        print("❌ 网络不可用")
    }
}

NetworkMonitor.shared.startMonitoring()
```

### 2. SwiftUI 集成

```swift
import SwiftUI
import Combine
import XFENetworkMonitor

class NetworkViewModel: ObservableObject {
    @Published var isOnline = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NetworkMonitor.shared.pathPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.isOnline = path.isNetworkAvailable
            }
            .store(in: &cancellables)
        
        NetworkMonitor.shared.startMonitoring()
    }
}

struct ContentView: View {
    @StateObject var viewModel = NetworkViewModel()
    
    var body: some View {
        Text(viewModel.isOnline ? "在线" : "离线")
    }
}
```

### 3. async/await（现代化）

```swift
import XFENetworkMonitor

Task {
    // 等待网络可用
    try await NetworkMonitor.shared.waitForNetwork(timeout: 30.0)
    print("✅ 网络已可用")
    
    // 或者监听网络变化
    for await path in NetworkMonitor.shared.pathUpdates {
        print("网络质量: \(path.quality.displayName)")
        if path.quality >= .good {
            break
        }
    }
}
```

---

## 📚 更多资源

- **完整文档**：[README.md](README.md)
- **发布指南**：[PUBLISHING_GUIDE.md](PUBLISHING_GUIDE.md)
- **集成示例**：[INTEGRATION_EXAMPLES.md](INTEGRATION_EXAMPLES.md)
- **架构文档**：[ARCHITECTURE.md](ARCHITECTURE.md)
- **示例代码**：`Sources/Examples/`

---

## ❓ 常见问题

### Q: CocoaPods 验证失败？

```bash
# 查看详细错误
pod lib lint XFENetworkMonitor.podspec --verbose

# 常见问题：
# 1. Git tag 未推送 → git push origin 1.0.0
# 2. 源文件路径错误 → 检查 s.source_files
# 3. Swift 版本不匹配 → 更新 s.swift_version
```

### Q: SPM 无法解析依赖？

```bash
# 清理缓存
rm -rf .build
swift package clean

# 重新解析
swift package resolve
swift build
```

### Q: 如何更新版本？

```bash
# 1. 更新版本号
# 编辑 XFENetworkMonitor.podspec: s.version = '1.0.1'

# 2. 提交并打 tag
git add .
git commit -m "Bump version to 1.0.1"
git tag 1.0.1
git push origin main
git push origin 1.0.1

# 3. 重新发布
pod trunk push XFENetworkMonitor.podspec --allow-warnings
```

---

## 🎉 完成！

现在你已经成功：
- ✅ 配置了 CocoaPods 和 SPM 支持
- ✅ 验证了所有配置文件
- ✅ 了解了如何发布和使用

**开始使用 XFENetworkMonitor 吧！** 🚀
