import SwiftUI
import Combine

/// 网络质量自适应内容加载视图
///
/// **功能**：根据网络质量自动调整内容加载策略
///
/// **设计理念**：
/// - 根据网络质量动态调整图片质量
/// - 网络断开时显示离线提示
/// - 低数据模式时减少数据使用
///
/// **为什么这样设计**：
/// - 提升用户体验（避免在慢网络下加载高清内容）
/// - 节省用户流量（尊重用户的数据使用偏好）
/// - 提供清晰的网络状态反馈
///
/// **使用方法**：
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         AdaptiveContentView()
///     }
/// }
/// ```
struct AdaptiveContentView: View {
    @StateObject private var viewModel = AdaptiveContentViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isOnline {
                    // 在线内容
                    ScrollView {
                        VStack(spacing: 20) {
                            // 网络质量指示器
                            NetworkQualityBanner(quality: viewModel.networkQuality)
                            
                            // 内容列表
                            ForEach(viewModel.contentItems) { item in
                                ContentCard(
                                    item: item,
                                    imageQuality: viewModel.imageQuality
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    // 离线提示
                    OfflineView()
                }
            }
            .navigationTitle("自适应内容")
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
        }
    }
}

/// 网络质量横幅
struct NetworkQualityBanner: View {
    let quality: NetworkQuality
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch quality {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .fair: return "exclamationmark.triangle"
        case .poor: return "xmark.circle"
        }
    }
    
    private var message: String {
        switch quality {
        case .excellent: return "网络质量优秀 - 高清内容"
        case .good: return "网络质量良好 - 标清内容"
        case .fair: return "网络质量一般 - 低清内容"
        case .poor: return "网络质量差 - 仅文本"
        }
    }
    
    private var backgroundColor: Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

/// 内容卡片
struct ContentCard: View {
    let item: ContentItem
    let imageQuality: ImageQuality
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片（根据质量加载不同尺寸）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Text("图片质量: \(imageQuality.rawValue)")
                        .foregroundColor(.secondary)
                )
            
            // 标题
            Text(item.title)
                .font(.headline)
            
            // 描述
            Text(item.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// 离线视图
struct OfflineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("网络未连接")
                .font(.title)
                .fontWeight(.bold)
            
            Text("请检查网络连接后重试")
                .foregroundColor(.secondary)
        }
    }
}

/// 内容项模型
struct ContentItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

/// 图片质量枚举
enum ImageQuality: String {
    case high = "高清"
    case medium = "标清"
    case low = "低清"
    case none = "无图片"
}

/// 自适应内容 ViewModel
class AdaptiveContentViewModel: ObservableObject {
    @Published var isOnline: Bool = false
    @Published var networkQuality: NetworkQuality = .poor
    @Published var imageQuality: ImageQuality = .none
    @Published var contentItems: [ContentItem] = []
    
    private let monitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadContent()
    }
    
    func startMonitoring() {
        monitor.pathPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                self?.updateStrategy(with: path)
            }
            .store(in: &cancellables)
        
        monitor.startMonitoring()
    }
    
    func stopMonitoring() {
        monitor.stopMonitoring()
        cancellables.removeAll()
    }
    
    private func updateStrategy(with path: NetworkPath) {
        isOnline = path.isNetworkAvailable
        networkQuality = path.quality
        
        // 根据网络质量调整图片质量
        imageQuality = determineImageQuality(for: path)
    }
    
    private func determineImageQuality(for path: NetworkPath) -> ImageQuality {
        if !path.isNetworkAvailable {
            return .none
        }
        
        switch path.quality {
        case .excellent:
            return .high
        case .good:
            return .medium
        case .fair:
            return .low
        case .poor:
            return .none
        }
    }
    
    private func loadContent() {
        contentItems = [
            ContentItem(title: "示例内容 1", description: "这是一段示例描述文本"),
            ContentItem(title: "示例内容 2", description: "根据网络质量自动调整加载策略"),
            ContentItem(title: "示例内容 3", description: "提供最佳的用户体验")
        ]
    }
}

