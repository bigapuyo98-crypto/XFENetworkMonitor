import Foundation

/// 多网络监听器协调器
///
/// **功能**：同时监听 WiFi 和蜂窝网络，实现智能网络切换策略
///
/// **设计理念**：
/// - 分别监听 WiFi 和蜂窝网络
/// - 优先使用 WiFi（成本低、速度快）
/// - WiFi 不可用时自动切换到蜂窝网络
/// - 提供网络切换通知
///
/// **为什么需要多监听器**：
/// - 更精细的网络控制
/// - 实现智能网络切换策略
/// - 优化用户体验和成本
///
/// **使用场景**：
/// - 大文件下载（优先 WiFi）
/// - 视频流媒体（根据网络类型调整码率）
/// - 数据同步（WiFi 时全量同步，蜂窝网络时增量同步）
///
/// **使用方法**：
/// ```swift
/// let coordinator = MultiMonitorCoordinator()
/// coordinator.delegate = self
/// coordinator.startMonitoring()
/// ```
class MultiMonitorCoordinator {
    
    // MARK: - 代理
    
    weak var delegate: MultiMonitorCoordinatorDelegate?
    
    // MARK: - 监听器
    
    /// WiFi 专用监听器
    ///
    /// **为什么单独监听 WiFi**：
    /// - WiFi 通常速度更快
    /// - WiFi 不产生流量费用
    /// - 可以实现 WiFi 优先策略
    private let wifiMonitor = NetworkMonitor.wifiMonitor
    
    /// 蜂窝网络专用监听器
    ///
    /// **为什么单独监听蜂窝网络**：
    /// - 蜂窝网络可能产生流量费用
    /// - 需要特殊的数据使用策略
    /// - 可以检测蜂窝网络质量
    private let cellularMonitor = NetworkMonitor.cellularMonitor
    
    // MARK: - 状态
    
    private(set) var isWiFiAvailable = false
    private(set) var isCellularAvailable = false
    
    /// 当前推荐的网络类型
    ///
    /// **决策逻辑**：
    /// 1. WiFi 可用 → 使用 WiFi
    /// 2. WiFi 不可用但蜂窝网络可用 → 使用蜂窝网络
    /// 3. 都不可用 → 离线模式
    var recommendedNetwork: ConnectionType {
        if isWiFiAvailable {
            return .wifi
        } else if isCellularAvailable {
            return .cellular
        } else {
            return .unavailable
        }
    }
    
    /// 是否应该限制数据使用
    ///
    /// **判断依据**：
    /// - 仅蜂窝网络可用时限制数据使用
    /// - WiFi 可用时不限制
    var shouldLimitDataUsage: Bool {
        return !isWiFiAvailable && isCellularAvailable
    }
    
    // MARK: - 初始化
    
    init() {
        setupMonitors()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - 公共方法
    
    /// 开始监听
    func startMonitoring() {
        wifiMonitor.startMonitoring()
        cellularMonitor.startMonitoring()
    }
    
    /// 停止监听
    func stopMonitoring() {
        wifiMonitor.stopMonitoring()
        cellularMonitor.stopMonitoring()
    }
    
    // MARK: - 私有方法
    
    private func setupMonitors() {
        // WiFi 监听器回调
        wifiMonitor.pathUpdateHandler = { [weak self] path in
            self?.handleWiFiUpdate(path)
        }
        
        // 蜂窝网络监听器回调
        cellularMonitor.pathUpdateHandler = { [weak self] path in
            self?.handleCellularUpdate(path)
        }
    }
    
    private func handleWiFiUpdate(_ path: NetworkPath) {
        let wasAvailable = isWiFiAvailable
        isWiFiAvailable = path.isNetworkAvailable
        
        // WiFi 状态变化
        if wasAvailable != isWiFiAvailable {
            if isWiFiAvailable {
                // WiFi 变为可用
                delegate?.multiMonitorCoordinator(self, didDetectWiFiAvailable: path)
                
                // 如果之前使用蜂窝网络，切换到 WiFi
                if isCellularAvailable {
                    delegate?.multiMonitorCoordinator(
                        self,
                        shouldSwitchFrom: .cellular,
                        to: .wifi,
                        reason: "WiFi 可用，建议切换以节省流量"
                    )
                }
            } else {
                // WiFi 变为不可用
                delegate?.multiMonitorCoordinator(self, didDetectWiFiUnavailable: path)
                
                // 如果蜂窝网络可用，切换到蜂窝网络
                if isCellularAvailable {
                    delegate?.multiMonitorCoordinator(
                        self,
                        shouldSwitchFrom: .wifi,
                        to: .cellular,
                        reason: "WiFi 不可用，切换到蜂窝网络"
                    )
                }
            }
        }
    }
    
    private func handleCellularUpdate(_ path: NetworkPath) {
        let wasAvailable = isCellularAvailable
        isCellularAvailable = path.isNetworkAvailable
        
        // 蜂窝网络状态变化
        if wasAvailable != isCellularAvailable {
            if isCellularAvailable {
                // 蜂窝网络变为可用
                delegate?.multiMonitorCoordinator(self, didDetectCellularAvailable: path)
                
                // 如果 WiFi 不可用，使用蜂窝网络
                if !isWiFiAvailable {
                    delegate?.multiMonitorCoordinator(
                        self,
                        shouldSwitchFrom: .unavailable,
                        to: .cellular,
                        reason: "蜂窝网络可用"
                    )
                }
            } else {
                // 蜂窝网络变为不可用
                delegate?.multiMonitorCoordinator(self, didDetectCellularUnavailable: path)
                
                // 如果 WiFi 也不可用，进入离线模式
                if !isWiFiAvailable {
                    delegate?.multiMonitorCoordinator(
                        self,
                        shouldSwitchFrom: .cellular,
                        to: .unavailable,
                        reason: "所有网络不可用"
                    )
                }
            }
        }
    }
}

// MARK: - MultiMonitorCoordinatorDelegate

/// 多监听器协调器代理
protocol MultiMonitorCoordinatorDelegate: AnyObject {
    /// WiFi 变为可用
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectWiFiAvailable path: NetworkPath)
    
    /// WiFi 变为不可用
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectWiFiUnavailable path: NetworkPath)
    
    /// 蜂窝网络变为可用
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectCellularAvailable path: NetworkPath)
    
    /// 蜂窝网络变为不可用
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectCellularUnavailable path: NetworkPath)
    
    /// 建议切换网络
    func multiMonitorCoordinator(
        _ coordinator: MultiMonitorCoordinator,
        shouldSwitchFrom oldNetwork: ConnectionType,
        to newNetwork: ConnectionType,
        reason: String
    )
}

// MARK: - 使用示例

/// 使用示例类
class MultiMonitorExample: MultiMonitorCoordinatorDelegate {
    private let coordinator = MultiMonitorCoordinator()
    
    func start() {
        coordinator.delegate = self
        coordinator.startMonitoring()
    }
    
    // MARK: - MultiMonitorCoordinatorDelegate
    
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectWiFiAvailable path: NetworkPath) {
        print("✅ WiFi 可用")
        print("   质量: \(path.quality.displayName)")
    }
    
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectWiFiUnavailable path: NetworkPath) {
        print("❌ WiFi 不可用")
    }
    
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectCellularAvailable path: NetworkPath) {
        print("✅ 蜂窝网络可用")
        print("   是否昂贵: \(path.isExpensive)")
    }
    
    func multiMonitorCoordinator(_ coordinator: MultiMonitorCoordinator, didDetectCellularUnavailable path: NetworkPath) {
        print("❌ 蜂窝网络不可用")
    }
    
    func multiMonitorCoordinator(
        _ coordinator: MultiMonitorCoordinator,
        shouldSwitchFrom oldNetwork: ConnectionType,
        to newNetwork: ConnectionType,
        reason: String
    ) {
        print("🔄 网络切换建议")
        print("   从: \(oldNetwork.displayName)")
        print("   到: \(newNetwork.displayName)")
        print("   原因: \(reason)")
        
        // 根据新网络类型调整应用行为
        switch newNetwork {
        case .wifi:
            enableHighQualityMode()
        case .cellular:
            enableDataSavingMode()
        case .unavailable:
            enableOfflineMode()
        default:
            break
        }
    }
    
    private func enableHighQualityMode() {
        print("   → 启用高质量模式")
    }
    
    private func enableDataSavingMode() {
        print("   → 启用数据节省模式")
    }
    
    private func enableOfflineMode() {
        print("   → 启用离线模式")
    }
}

