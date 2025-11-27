import SwiftUI
import Combine

/// SwiftUI 网络状态指示器视图
///
/// **功能**：实时显示网络连接状态、类型和质量
///
/// **设计理念**：
/// - 使用 @StateObject 管理 NetworkMonitor 生命周期
/// - 使用 @Published 属性实现响应式更新
/// - 使用 Combine 订阅网络变化
///
/// **为什么这样设计**：
/// - @StateObject 确保 monitor 在视图生命周期内保持存在
/// - Combine 提供声明式的数据流处理
/// - 自动内存管理，无需手动清理
///
/// **使用方法**：
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NetworkStatusView()
///     }
/// }
/// ```
struct NetworkStatusView: View {
    @StateObject private var viewModel = NetworkStatusViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // 网络状态图标
            Image(systemName: viewModel.statusIcon)
                .font(.system(size: 60))
                .foregroundColor(viewModel.statusColor)
                .animation(.easeInOut, value: viewModel.isOnline)
            
            // 连接状态文本
            Text(viewModel.statusText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(viewModel.statusColor)
            
            // 详细信息
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "连接类型", value: viewModel.connectionType)
                InfoRow(label: "网络质量", value: viewModel.networkQuality)
                InfoRow(label: "是否昂贵", value: viewModel.isExpensive ? "是" : "否")
                InfoRow(label: "是否受限", value: viewModel.isConstrained ? "是" : "否")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // 建议信息
            if let suggestion = viewModel.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

/// 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

/// 网络状态 ViewModel
///
/// **职责**：
/// - 管理 NetworkMonitor 实例
/// - 将网络状态转换为 UI 数据
/// - 提供网络建议信息
///
/// **为什么使用 ViewModel**：
/// - 分离业务逻辑和 UI 逻辑
/// - 便于单元测试
/// - 符合 MVVM 架构模式
class NetworkStatusViewModel: ObservableObject {
    // MARK: - Published 属性（自动触发 UI 更新）
    
    @Published var isOnline: Bool = false
    @Published var connectionType: String = "未知"
    @Published var networkQuality: String = "未知"
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    
    // MARK: - 私有属性
    
    private let monitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 计算属性（UI 展示）
    
    var statusIcon: String {
        if !isOnline {
            return "wifi.slash"
        }
        switch connectionType {
        case "WiFi": return "wifi"
        case "蜂窝网络": return "antenna.radiowaves.left.and.right"
        case "有线网络": return "cable.connector"
        default: return "network"
        }
    }
    
    var statusColor: Color {
        if !isOnline { return .red }
        switch networkQuality {
        case "优秀": return .green
        case "良好": return .blue
        case "一般": return .orange
        default: return .red
        }
    }
    
    var statusText: String {
        isOnline ? "网络已连接" : "网络未连接"
    }
    
    var suggestion: String? {
        if !isOnline {
            return "请检查网络连接"
        }
        if isConstrained {
            return "低数据模式已开启，建议减少数据使用"
        }
        if isExpensive {
            return "当前使用蜂窝网络，可能产生流量费用"
        }
        return nil
    }
    
    // MARK: - 方法
    
    func startMonitoring() {
        // 使用 Combine 订阅网络变化
        monitor.pathPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.updateUI(with: path)
            }
            .store(in: &cancellables)
        
        monitor.startMonitoring()
    }
    
    func stopMonitoring() {
        monitor.stopMonitoring()
        cancellables.removeAll()
    }
    
    private func updateUI(with path: NetworkPath) {
        isOnline = path.isNetworkAvailable
        connectionType = path.connectionType.displayName
        networkQuality = path.quality.displayName
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }
}

