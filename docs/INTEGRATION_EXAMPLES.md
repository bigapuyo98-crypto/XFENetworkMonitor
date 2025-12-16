# XFENetworkMonitor 集成示例

本文档提供详细的集成示例，帮助你快速在项目中使用 XFENetworkMonitor。

---

## 📱 CocoaPods 集成示例

### 步骤 1：创建 Podfile

在你的 iOS 项目根目录创建 `Podfile`：

```ruby
# Podfile

platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  # XFENetworkMonitor
  pod 'XFENetworkMonitor', '~> 1.0'
  
  # 其他依赖...
end

# 如果有测试目标
target 'YourAppTests' do
  inherit! :search_paths
end
```

### 步骤 2：安装依赖

```bash
# 安装 CocoaPods（如果未安装）
sudo gem install cocoapods

# 安装依赖
pod install

# 打开工作空间（重要！）
open YourApp.xcworkspace
```

### 步骤 3：在代码中使用

**AppDelegate.swift**：

```swift
import UIKit
import XFENetworkMonitor

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // 启动网络监听
        setupNetworkMonitoring()
        
        return true
    }
    
    private func setupNetworkMonitoring() {
        // 使用闭包回调
        NetworkMonitor.shared.pathUpdateHandler = { path in
            print("📡 网络状态: \(path.connectionType.displayName)")
            print("📊 网络质量: \(path.quality.displayName)")
            
            // 根据网络状态调整应用行为
            if !path.isNetworkAvailable {
                // 切换到离线模式
                NotificationCenter.default.post(
                    name: NSNotification.Name("SwitchToOfflineMode"),
                    object: nil
                )
            }
        }
        
        // 启动监听
        NetworkMonitor.shared.startMonitoring()
    }
}
```

**ViewController.swift**：

```swift
import UIKit
import XFENetworkMonitor

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 方式 1：使用闭包
        NetworkMonitor.shared.pathUpdateHandler = { [weak self] path in
            self?.updateUI(with: path)
        }
        
        // 方式 2：使用代理
        NetworkMonitor.shared.delegate = self
        
        // 方式 3：使用通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkDidChange(_:)),
            name: .networkPathDidChange,
            object: nil
        )
    }
    
    private func updateUI(with path: NetworkPath) {
        DispatchQueue.main.async {
            self.statusLabel.text = path.isNetworkAvailable ? "在线" : "离线"
            self.qualityLabel.text = "质量: \(path.quality.displayName)"
        }
    }
    
    @objc private func networkDidChange(_ notification: Notification) {
        if let path = notification.userInfo?[NetworkNotificationKeys.networkPath] as? NetworkPath {
            updateUI(with: path)
        }
    }
}

extension ViewController: NetworkMonitorDelegate {
    func networkMonitor(_ monitor: NetworkMonitor, didUpdatePath path: NetworkPath) {
        updateUI(with: path)
    }
    
    func networkMonitor(_ monitor: NetworkMonitor, didEncounterError error: Error) {
        print("❌ 网络监听错误: \(error)")
    }
}
```

---

## 📦 Swift Package Manager 集成示例

### 方式 1：通过 Xcode UI

1. 打开你的项目
2. 选择项目文件（蓝色图标）
3. 选择你的 target
4. 点击 "General" 标签
5. 滚动到 "Frameworks, Libraries, and Embedded Content"
6. 点击 "+" 按钮
7. 选择 "Add Package Dependency..."
8. 输入仓库 URL：
   ```
   git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git
   ```
9. 选择版本规则：
   - **Dependency Rule**: Up to Next Major Version
   - **Version**: 1.0.0
10. 点击 "Add Package"
11. 选择 "XFENetworkMonitor" 库
12. 点击 "Add Package"

### 方式 2：通过 Package.swift（纯 SPM 项目）

创建或编辑 `Package.swift`：

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "YourApp",
            targets: ["YourApp"]
        )
    ],
    dependencies: [
        // XFENetworkMonitor 依赖
        .package(
            url: "git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "YourApp",
            dependencies: [
                .product(name: "XFENetworkMonitor", package: "XFENetworkMonitor")
            ]
        )
    ]
)
```

### 步骤 2：解析依赖

```bash
# 解析依赖
swift package resolve

# 更新依赖
swift package update

# 构建项目
swift build

# 运行项目
swift run
```

### 步骤 3：在代码中使用

**main.swift** 或 **App.swift**：

```swift
import Foundation
import XFENetworkMonitor

@main
struct YourApp {
    static func main() async {
        // 启动网络监听
        NetworkMonitor.shared.startMonitoring()
        
        // 使用 async/await
        await monitorNetwork()
    }
    
    static func monitorNetwork() async {
        for await path in NetworkMonitor.shared.pathUpdates {
            print("📡 网络状态: \(path.connectionType.displayName)")
            print("📊 网络质量: \(path.quality.displayName)")
            
            if path.quality >= .good {
                print("✅ 网络质量良好，可以开始任务")
                break
            }
        }
    }
}
```

---

## 🎯 SwiftUI 完整示例

### CocoaPods 项目

**ContentView.swift**：

```swift
import SwiftUI
import Combine
import XFENetworkMonitor

// MARK: - ViewModel

class NetworkViewModel: ObservableObject {
    @Published var isOnline: Bool = false
    @Published var connectionType: String = "未知"
    @Published var networkQuality: String = "未知"
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // 使用 Combine 订阅网络变化
        NetworkMonitor.shared.pathPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.updateState(with: path)
            }
            .store(in: &cancellables)
        
        // 启动监听
        NetworkMonitor.shared.startMonitoring()
    }
    
    private func updateState(with path: NetworkPath) {
        isOnline = path.isNetworkAvailable
        connectionType = path.connectionType.displayName
        networkQuality = path.quality.displayName
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }
    
    deinit {
        NetworkMonitor.shared.stopMonitoring()
    }
}

// MARK: - View

struct ContentView: View {
    @StateObject private var viewModel = NetworkViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section("网络状态") {
                    StatusRow(
                        icon: viewModel.isOnline ? "wifi" : "wifi.slash",
                        title: "连接状态",
                        value: viewModel.isOnline ? "在线" : "离线",
                        color: viewModel.isOnline ? .green : .red
                    )
                    
                    StatusRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "连接类型",
                        value: viewModel.connectionType,
                        color: .blue
                    )
                    
                    StatusRow(
                        icon: "speedometer",
                        title: "网络质量",
                        value: viewModel.networkQuality,
                        color: qualityColor
                    )
                }
                
                Section("网络特性") {
                    FeatureRow(
                        title: "昂贵网络",
                        isEnabled: viewModel.isExpensive,
                        description: "蜂窝网络可能产生流量费用"
                    )
                    
                    FeatureRow(
                        title: "受限网络",
                        isEnabled: viewModel.isConstrained,
                        description: "低数据模式已开启"
                    )
                }
            }
            .navigationTitle("网络监控")
        }
    }
    
    private var qualityColor: Color {
        switch viewModel.networkQuality {
        case "优秀": return .green
        case "良好": return .blue
        case "一般": return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct FeatureRow: View {
    let title: String
    let isEnabled: Bool
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(isEnabled ? .orange : .gray)
            }
            
            if isEnabled {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```

---

## 🔄 UIKit 完整示例

### 网络状态视图控制器

```swift
import UIKit
import XFENetworkMonitor

class NetworkStatusViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNetworkMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "网络状态"
        view.backgroundColor = .systemBackground
        
        view.addSubview(statusImageView)
        view.addSubview(statusLabel)
        view.addSubview(detailsStackView)
        
        NSLayoutConstraint.activate([
            statusImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            statusImageView.widthAnchor.constraint(equalToConstant: 100),
            statusImageView.heightAnchor.constraint(equalToConstant: 100),
            
            statusLabel.topAnchor.constraint(equalTo: statusImageView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            detailsStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            detailsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupNetworkMonitoring() {
        // 使用闭包回调
        NetworkMonitor.shared.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateUI(with: path)
            }
        }
        
        // 启动监听
        NetworkMonitor.shared.startMonitoring()
        
        // 如果已有当前状态，立即更新
        if let currentPath = NetworkMonitor.shared.currentPath {
            updateUI(with: currentPath)
        }
    }
    
    // MARK: - UI Update
    
    private func updateUI(with path: NetworkPath) {
        // 更新状态图标
        let iconName = path.isNetworkAvailable ? "wifi" : "wifi.slash"
        statusImageView.image = UIImage(systemName: iconName)
        statusImageView.tintColor = path.isNetworkAvailable ? .systemGreen : .systemRed
        
        // 更新状态文本
        statusLabel.text = path.isNetworkAvailable ? "网络已连接" : "网络未连接"
        statusLabel.textColor = path.isNetworkAvailable ? .systemGreen : .systemRed
        
        // 清除旧的详情
        detailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新的详情
        addDetailRow(title: "连接类型", value: path.connectionType.displayName)
        addDetailRow(title: "网络质量", value: path.quality.displayName)
        addDetailRow(title: "是否昂贵", value: path.isExpensive ? "是" : "否")
        addDetailRow(title: "是否受限", value: path.isConstrained ? "是" : "否")
        addDetailRow(title: "支持 IPv4", value: path.supportsIPv4 ? "是" : "否")
        addDetailRow(title: "支持 IPv6", value: path.supportsIPv6 ? "是" : "否")
        
        // 添加建议
        if let suggestion = getSuggestion(for: path) {
            addSuggestionView(suggestion)
        }
    }
    
    private func addDetailRow(title: String, value: String) {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .medium)
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])
        
        detailsStackView.addArrangedSubview(containerView)
    }
    
    private func addSuggestionView(_ suggestion: String) {
        let containerView = UIView()
        containerView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemOrange.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iconImageView.tintColor = .systemOrange
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let suggestionLabel = UILabel()
        suggestionLabel.text = suggestion
        suggestionLabel.font = .systemFont(ofSize: 14)
        suggestionLabel.textColor = .label
        suggestionLabel.numberOfLines = 0
        suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(suggestionLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            suggestionLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            suggestionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            suggestionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            suggestionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        detailsStackView.addArrangedSubview(containerView)
    }
    
    private func getSuggestion(for path: NetworkPath) -> String? {
        if !path.isNetworkAvailable {
            return "请检查网络连接"
        }
        if path.isConstrained {
            return "低数据模式已开启，建议减少数据使用"
        }
        if path.isExpensive {
            return "当前使用蜂窝网络，可能产生流量费用"
        }
        if path.quality == .poor {
            return "网络质量较差，建议稍后重试"
        }
        return nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        NetworkMonitor.shared.pathUpdateHandler = nil
    }
}
```

---

## 🚀 async/await 高级示例

### 等待网络可用后执行任务

```swift
import Foundation
import XFENetworkMonitor

class DataSyncManager {
    
    func syncData() async throws {
        print("📤 准备同步数据...")
        
        // 等待网络可用（最多 30 秒）
        do {
            try await NetworkMonitor.shared.waitForNetwork(timeout: 30.0)
            print("✅ 网络已可用，开始同步")
        } catch {
            print("❌ 等待网络超时")
            throw SyncError.networkTimeout
        }
        
        // 执行同步任务
        try await performSync()
    }
    
    func syncDataOverWiFi() async throws {
        print("📤 准备通过 WiFi 同步大文件...")
        
        // 等待 WiFi 连接（最多 60 秒）
        do {
            try await NetworkMonitor.shared.waitForWiFi(timeout: 60.0)
            print("✅ WiFi 已连接，开始同步")
        } catch {
            print("❌ 等待 WiFi 超时")
            throw SyncError.wifiTimeout
        }
        
        // 执行大文件同步
        try await performLargeFileSync()
    }
    
    func monitorQualityAndSync() async {
        print("📊 监听网络质量...")
        
        for await path in NetworkMonitor.shared.pathUpdates {
            print("当前质量: \(path.quality.displayName)")
            
            if path.quality >= .good {
                print("✅ 网络质量良好，开始同步")
                try? await performSync()
                break
            } else {
                print("⚠️ 网络质量不佳，继续等待...")
            }
        }
    }
    
    private func performSync() async throws {
        // 模拟同步任务
        try await Task.sleep(nanoseconds: 2_000_000_000)
        print("✅ 同步完成")
    }
    
    private func performLargeFileSync() async throws {
        // 模拟大文件同步
        try await Task.sleep(nanoseconds: 5_000_000_000)
        print("✅ 大文件同步完成")
    }
}

enum SyncError: Error {
    case networkTimeout
    case wifiTimeout
}

// 使用示例
Task {
    let manager = DataSyncManager()
    
    // 等待网络可用后同步
    try? await manager.syncData()
    
    // 等待 WiFi 后同步大文件
    try? await manager.syncDataOverWiFi()
    
    // 监听质量变化
    await manager.monitorQualityAndSync()
}
```

---

## 📝 总结

### CocoaPods 集成要点

1. ✅ 创建 `Podfile`
2. ✅ 运行 `pod install`
3. ✅ 使用 `.xcworkspace` 打开项目
4. ✅ `import XFENetworkMonitor`

### SPM 集成要点

1. ✅ 通过 Xcode UI 或 `Package.swift` 添加依赖
2. ✅ 运行 `swift package resolve`
3. ✅ `import XFENetworkMonitor`

### 使用建议

- 🎯 在 `AppDelegate` 中启动监听
- 🎯 使用合适的回调机制（闭包、代理、Combine 等）
- 🎯 根据网络状态调整应用行为
- 🎯 在不需要时停止监听以节省资源

---

**更多示例请参考项目中的 `Sources/Examples/` 目录！**
