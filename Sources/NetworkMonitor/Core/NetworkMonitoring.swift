import Foundation

/// 网络监测核心协议
///
/// 定义网络监测的核心接口，任何需要网络监测功能的类都可以遵守此协议
///
/// **设计理念**：
/// 1. 面向协议编程 - 先定义协议，再实现具体类型
/// 2. 协议扩展 - 为协议提供默认实现，减少重复代码
/// 3. 依赖抽象 - 上层依赖协议而非具体实现
///
/// **使用场景**：
/// - 需要监测网络状态变化的应用
/// - 需要根据网络质量调整行为的服务
/// - 需要 Mock 网络状态进行测试
///
/// **注意事项**：
/// - 必须调用 startMonitoring() 才能开始监听
/// - 使用完毕后应调用 stopMonitoring() 释放资源
/// - 所有回调默认在主线程执行
///
/// **为什么使用协议**：
/// - 提高可测试性：可以轻松创建 Mock 实现用于单元测试
/// - 降低耦合度：上层代码依赖协议而非具体实现
/// - 增强扩展性：可以有多种实现方式（真实监听器、Mock、缓存等）
public protocol NetworkMonitoring: AnyObject {
    
    // MARK: - Core Properties
    
    /// 当前网络路径信息
    ///
    /// **返回值**：当前的网络路径，如果监听未启动则返回 nil
    /// **线程安全**：可以在任意线程访问
    ///
    /// **使用示例**：
    /// ```swift
    /// if let path = monitor.currentPath {
    ///     print("连接类型: \(path.connectionType.displayName)")
    ///     print("网络质量: \(path.quality.displayName)")
    /// }
    /// ```
    var currentPath: NetworkPath? { get }
    
    /// 是否正在监听网络变化
    ///
    /// **用途**：检查监听器的运行状态，避免重复启动或停止
    /// **返回值**：true 表示正在监听，false 表示未启动
    var isMonitoring: Bool { get }
    
    // MARK: - Core Methods
    
    /// 开始监听网络变化
    ///
    /// **功能**：启动网络状态监听，开始接收网络变化通知
    /// **线程安全**：可以在任意线程调用
    /// **重复调用**：多次调用是安全的，不会重复启动监听
    ///
    /// **执行流程**：
    /// 1. 检查当前监听状态
    /// 2. 启动底层网络监听器
    /// 3. 更新监听状态标记
    /// 4. 触发监听开始的回调通知
    ///
    /// **使用示例**：
    /// ```swift
    /// let monitor = NetworkMonitor.shared
    /// monitor.startMonitoring()
    /// ```
    func startMonitoring()
    
    /// 停止监听网络变化
    ///
    /// **功能**：停止网络状态监听，释放系统资源
    /// **线程安全**：可以在任意线程调用
    /// **重复调用**：多次调用是安全的，不会重复停止监听
    ///
    /// **执行流程**：
    /// 1. 检查当前监听状态
    /// 2. 停止底层网络监听器
    /// 3. 更新监听状态标记
    /// 4. 触发监听停止的回调通知
    ///
    /// **使用场景**：
    /// - 应用进入后台时节省资源
    /// - 页面销毁时清理监听器
    /// - 临时暂停网络监听
    ///
    /// **使用示例**：
    /// ```swift
    /// deinit {
    ///     monitor.stopMonitoring()
    /// }
    /// ```
    func stopMonitoring()
}

// MARK: - Protocol Extensions (Default Implementations)

/// 协议扩展 - 提供基于 currentPath 的便捷属性默认实现
///
/// **设计优势**：
/// - 减少重复代码：所有遵守协议的类型自动获得这些功能
/// - 保持一致性：所有实现使用相同的逻辑
/// - 易于维护：修改一处，所有实现同步更新
public extension NetworkMonitoring {
    
    /// 网络是否可用
    ///
    /// **判断依据**：基于当前网络路径的状态判断网络可用性
    /// **返回值**：网络可用返回 true，否则返回 false
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.isNetworkAvailable {
    ///     performNetworkRequest()
    /// } else {
    ///     showOfflineMessage()
    /// }
    /// ```
    var isNetworkAvailable: Bool {
        return currentPath?.isNetworkAvailable ?? false
    }
    
    /// 当前连接类型
    ///
    /// **返回值**：当前的连接类型，如果网络不可用则返回 .unavailable
    ///
    /// **使用示例**：
    /// ```swift
    /// switch monitor.connectionType {
    /// case .wifi:
    ///     enableHighQualityMode()
    /// case .cellular:
    ///     enableDataSavingMode()
    /// default:
    ///     showOfflineMode()
    /// }
    /// ```
    var connectionType: ConnectionType {
        return currentPath?.connectionType ?? .unavailable
    }

    /// 当前网络质量
    ///
    /// **返回值**：基于网络路径信息评估的质量等级，如果网络不可用则返回 .poor
    ///
    /// **评估维度**：
    /// - 网络可用性（最高优先级）
    /// - 用户数据使用偏好（低数据模式）
    /// - 网络成本（蜂窝网络 vs WiFi）
    /// - 连接稳定性和速度
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.networkQuality.isHighQuality {
    ///     startVideoStreaming()
    /// } else {
    ///     showLowQualityWarning()
    /// }
    /// ```
    var networkQuality: NetworkQuality {
        return currentPath?.quality ?? .poor
    }

    /// 是否为昂贵网络
    ///
    /// **判断依据**：蜂窝网络、个人热点等可能产生流量费用的网络
    /// **返回值**：昂贵网络返回 true，否则返回 false
    ///
    /// **应用策略**：
    /// - 昂贵网络时暂停大文件下载
    /// - 降低媒体质量
    /// - 提示用户切换到 WiFi
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.isExpensiveNetwork {
    ///     pauseLargeDownloads()
    ///     showDataUsageWarning()
    /// }
    /// ```
    var isExpensiveNetwork: Bool {
        return currentPath?.isExpensive ?? false
    }

    /// 是否为受限网络
    ///
    /// **判断依据**：用户是否开启了低数据模式
    /// **返回值**：受限网络返回 true，否则返回 false
    ///
    /// **应用策略**：
    /// - 尊重用户意图，减少数据使用
    /// - 降低图片质量
    /// - 暂停自动更新
    /// - 减少预加载
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.isConstrainedNetwork {
    ///     imageQuality = .low
    ///     disableAutoPlay()
    /// }
    /// ```
    var isConstrainedNetwork: Bool {
        return currentPath?.isConstrained ?? false
    }

    /// 是否为 WiFi 连接
    ///
    /// **用途**：便捷方法判断当前是否为 WiFi 连接
    /// **返回值**：WiFi 连接返回 true，否则返回 false
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.isWiFiConnection {
    ///     startBackgroundSync()
    /// }
    /// ```
    var isWiFiConnection: Bool {
        return connectionType == .wifi
    }

    /// 是否为蜂窝连接
    ///
    /// **用途**：便捷方法判断当前是否为蜂窝网络连接
    /// **返回值**：蜂窝连接返回 true，否则返回 false
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.isCellularConnection {
    ///     enableDataSavingMode()
    /// }
    /// ```
    var isCellularConnection: Bool {
        return connectionType == .cellular
    }
}

// MARK: - Convenience Methods

/// 协议扩展 - 提供便捷的辅助方法
///
/// **设计目的**：简化常见的网络状态判断和操作
public extension NetworkMonitoring {

    /// 检查是否适合进行大文件传输
    ///
    /// **判断条件**：
    /// - 网络可用
    /// - 网络质量为 excellent
    /// - 不是移动网络（避免流量费用）
    ///
    /// **返回值**：适合大文件传输返回 true，否则返回 false
    ///
    /// **使用示例**：
    /// ```swift
    /// if monitor.isSuitableForLargeTransfers {
    ///     startLargeFileDownload()
    /// } else {
    ///     showWaitForWiFiMessage()
    /// }
    /// ```
    var isSuitableForLargeTransfers: Bool {
        guard let path = currentPath else { return false }
        return path.isGoodForLargeTransfers
    }

    /// 检查是否适合高质量媒体传输
    ///
    /// **判断条件**：
    /// - 网络可用
    /// - 网络质量为 good 及以上
    ///
    /// **返回值**：适合高质量媒体返回 true，否则返回 false
    ///
    /// **使用示例**：
    /// ```swift
    /// let videoQuality: VideoQuality = monitor.isSuitableForHighQualityMedia ? .high : .low
    /// ```
    var isSuitableForHighQualityMedia: Bool {
        guard let path = currentPath else { return false }
        return path.isGoodForHighQualityMedia
    }
}
