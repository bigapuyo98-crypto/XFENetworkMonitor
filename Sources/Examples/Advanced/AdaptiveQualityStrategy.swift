import Foundation

/// 网络质量自适应策略
///
/// **功能**：根据网络质量自动调整内容质量（图片、视频等）
///
/// **设计理念**：
/// - 根据网络质量动态调整内容质量
/// - 提供多级质量配置
/// - 支持自定义策略
///
/// **为什么需要自适应策略**：
/// - 提升用户体验（避免在慢网络下加载高清内容）
/// - 节省用户流量
/// - 减少加载时间
///
/// **使用场景**：
/// - 图片加载（根据网络质量选择不同分辨率）
/// - 视频播放（根据网络质量调整码率）
/// - 内容预加载（根据网络质量决定是否预加载）
///
/// **使用方法**：
/// ```swift
/// let strategy = AdaptiveQualityStrategy()
/// strategy.delegate = self
/// strategy.startMonitoring()
/// ```
class AdaptiveQualityStrategy {
    
    // MARK: - 代理
    
    weak var delegate: AdaptiveQualityStrategyDelegate?
    
    // MARK: - 配置
    
    /// 图片质量配置
    ///
    /// **为什么需要配置**：
    /// - 不同应用对质量的要求不同
    /// - 允许用户自定义偏好
    /// - 支持 A/B 测试
    struct ImageQualityConfig {
        let excellent: ImageResolution  // 网络质量优秀时
        let good: ImageResolution       // 网络质量良好时
        let fair: ImageResolution       // 网络质量一般时
        let poor: ImageResolution       // 网络质量差时
        
        static let `default` = ImageQualityConfig(
            excellent: .high,
            good: .medium,
            fair: .low,
            poor: .thumbnail
        )
    }
    
    /// 视频质量配置
    struct VideoQualityConfig {
        let excellent: VideoBitrate
        let good: VideoBitrate
        let fair: VideoBitrate
        let poor: VideoBitrate
        
        static let `default` = VideoQualityConfig(
            excellent: .hd1080p,
            good: .hd720p,
            fair: .sd480p,
            poor: .sd360p
        )
    }
    
    // MARK: - 属性
    
    private let monitor = NetworkMonitor.shared
    var imageQualityConfig = ImageQualityConfig.default
    var videoQualityConfig = VideoQualityConfig.default
    
    private(set) var currentImageQuality: ImageResolution = .thumbnail
    private(set) var currentVideoQuality: VideoBitrate = .sd360p
    
    // MARK: - 初始化
    
    init() {
        setupMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - 公共方法
    
    func startMonitoring() {
        monitor.startMonitoring()
    }
    
    func stopMonitoring() {
        monitor.stopMonitoring()
    }
    
    /// 获取推荐的图片质量
    ///
    /// **决策逻辑**：
    /// 1. 检查网络质量
    /// 2. 查找对应的质量配置
    /// 3. 考虑用户偏好（如果有）
    func recommendedImageQuality(for path: NetworkPath) -> ImageResolution {
        switch path.quality {
        case .excellent: return imageQualityConfig.excellent
        case .good: return imageQualityConfig.good
        case .fair: return imageQualityConfig.fair
        case .poor: return imageQualityConfig.poor
        }
    }
    
    /// 获取推荐的视频质量
    func recommendedVideoQuality(for path: NetworkPath) -> VideoBitrate {
        switch path.quality {
        case .excellent: return videoQualityConfig.excellent
        case .good: return videoQualityConfig.good
        case .fair: return videoQualityConfig.fair
        case .poor: return videoQualityConfig.poor
        }
    }
    
    /// 是否应该预加载内容
    ///
    /// **决策依据**：
    /// - 网络质量良好或优秀时预加载
    /// - 非昂贵网络时预加载
    /// - 非受限网络时预加载
    func shouldPreloadContent(for path: NetworkPath) -> Bool {
        return path.quality >= .good && !path.isExpensive && !path.isConstrained
    }
    
    // MARK: - 私有方法
    
    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkChange(path)
        }
    }
    
    private func handleNetworkChange(_ path: NetworkPath) {
        let newImageQuality = recommendedImageQuality(for: path)
        let newVideoQuality = recommendedVideoQuality(for: path)
        
        // 图片质量变化
        if newImageQuality != currentImageQuality {
            let oldQuality = currentImageQuality
            currentImageQuality = newImageQuality
            
            delegate?.adaptiveQualityStrategy(
                self,
                didChangeImageQuality: newImageQuality,
                from: oldQuality,
                reason: "网络质量变化: \(path.quality.displayName)"
            )
        }
        
        // 视频质量变化
        if newVideoQuality != currentVideoQuality {
            let oldQuality = currentVideoQuality
            currentVideoQuality = newVideoQuality
            
            delegate?.adaptiveQualityStrategy(
                self,
                didChangeVideoQuality: newVideoQuality,
                from: oldQuality,
                reason: "网络质量变化: \(path.quality.displayName)"
            )
        }
        
        // 预加载策略变化
        let shouldPreload = shouldPreloadContent(for: path)
        delegate?.adaptiveQualityStrategy(self, shouldPreloadContent: shouldPreload)
    }
}

// MARK: - 质量枚举

/// 图片分辨率
enum ImageResolution: String, Comparable {
    case thumbnail = "缩略图"    // 100x100
    case low = "低清"            // 480x480
    case medium = "标清"         // 1024x1024
    case high = "高清"           // 2048x2048
    
    static func < (lhs: ImageResolution, rhs: ImageResolution) -> Bool {
        let order: [ImageResolution] = [.thumbnail, .low, .medium, .high]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

/// 视频码率
enum VideoBitrate: String, Comparable {
    case sd360p = "360p"    // 500 kbps
    case sd480p = "480p"    // 1 Mbps
    case hd720p = "720p"    // 2.5 Mbps
    case hd1080p = "1080p"  // 5 Mbps
    
    static func < (lhs: VideoBitrate, rhs: VideoBitrate) -> Bool {
        let order: [VideoBitrate] = [.sd360p, .sd480p, .hd720p, .hd1080p]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - AdaptiveQualityStrategyDelegate

protocol AdaptiveQualityStrategyDelegate: AnyObject {
    /// 图片质量变化
    func adaptiveQualityStrategy(
        _ strategy: AdaptiveQualityStrategy,
        didChangeImageQuality newQuality: ImageResolution,
        from oldQuality: ImageResolution,
        reason: String
    )
    
    /// 视频质量变化
    func adaptiveQualityStrategy(
        _ strategy: AdaptiveQualityStrategy,
        didChangeVideoQuality newQuality: VideoBitrate,
        from oldQuality: VideoBitrate,
        reason: String
    )
    
    /// 预加载策略变化
    func adaptiveQualityStrategy(_ strategy: AdaptiveQualityStrategy, shouldPreloadContent: Bool)
}

// MARK: - 使用示例

class AdaptiveQualityExample: AdaptiveQualityStrategyDelegate {
    private let strategy = AdaptiveQualityStrategy()
    
    func start() {
        strategy.delegate = self
        strategy.startMonitoring()
    }
    
    func adaptiveQualityStrategy(
        _ strategy: AdaptiveQualityStrategy,
        didChangeImageQuality newQuality: ImageResolution,
        from oldQuality: ImageResolution,
        reason: String
    ) {
        print("📷 图片质量变化")
        print("   从: \(oldQuality.rawValue)")
        print("   到: \(newQuality.rawValue)")
        print("   原因: \(reason)")
        
        // 重新加载可见图片
        reloadVisibleImages(with: newQuality)
    }
    
    func adaptiveQualityStrategy(
        _ strategy: AdaptiveQualityStrategy,
        didChangeVideoQuality newQuality: VideoBitrate,
        from oldQuality: VideoBitrate,
        reason: String
    ) {
        print("🎬 视频质量变化")
        print("   从: \(oldQuality.rawValue)")
        print("   到: \(newQuality.rawValue)")
        print("   原因: \(reason)")
        
        // 调整视频播放器码率
        adjustVideoPlayerBitrate(to: newQuality)
    }
    
    func adaptiveQualityStrategy(_ strategy: AdaptiveQualityStrategy, shouldPreloadContent: Bool) {
        print("📦 预加载策略: \(shouldPreloadContent ? "启用" : "禁用")")
        
        if shouldPreloadContent {
            startPreloading()
        } else {
            stopPreloading()
        }
    }
    
    private func reloadVisibleImages(with quality: ImageResolution) {
        print("   → 重新加载图片（质量: \(quality.rawValue)）")
    }
    
    private func adjustVideoPlayerBitrate(to bitrate: VideoBitrate) {
        print("   → 调整视频码率（\(bitrate.rawValue)）")
    }
    
    private func startPreloading() {
        print("   → 开始预加载内容")
    }
    
    private func stopPreloading() {
        print("   → 停止预加载内容")
    }
}

