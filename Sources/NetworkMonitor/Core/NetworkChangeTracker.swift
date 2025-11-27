import Foundation

/// 网络变化追踪器
///
/// **职责**：追踪和记录网络状态的变化历史，提供变化分析和统计功能
///
/// **设计理念**：
/// 1. **高效存储** - 使用环形缓冲区避免内存无限增长
/// 2. **智能过滤** - 仅记录有意义的变化，避免噪音数据
/// 3. **多维分析** - 从时间、质量、类型等多个维度分析变化
/// 4. **线程安全** - 使用专用队列保护内部状态
///
/// **使用场景**：
/// - 分析网络连接稳定性
/// - 检测频繁断连模式
/// - 追踪网络质量变化趋势
/// - 生成网络使用报告
///
/// **使用示例**：
/// ```swift
/// let tracker = NetworkChangeTracker()
///
/// // 记录网络变化
/// monitor.pathUpdateHandler = { [weak tracker] newPath in
///     tracker?.recordPathChange(newPath, previousPath: oldPath)
/// }
///
/// // 获取统计信息
/// let stats = tracker.getStatistics()
/// print("稳定性得分: \(stats.stabilityScore)")
/// ```
public class NetworkChangeTracker {
    
    // MARK: - Configuration
    
    /// 追踪配置
    public struct Configuration {
        /// 最大历史记录数量（环形缓冲区大小）
        ///
        /// **为什么需要限制**：
        /// - 避免内存无限增长
        /// - 保持查询性能
        /// - 平衡数据完整性和资源使用
        public let maxHistoryCount: Int
        
        /// 是否启用智能过滤（过滤掉短暂的网络抖动）
        ///
        /// **好处**：
        /// - 减少噪音数据
        /// - 提高分析准确性
        /// - 降低存储开销
        public let enableSmartFiltering: Bool
        
        /// 智能过滤的最小持续时间（秒）
        ///
        /// **用途**：过滤掉持续时间过短的网络变化
        public let minimumDuration: TimeInterval
        
        /// 是否记录详细的变化信息
        ///
        /// **权衡**：
        /// - 启用：提供更多调试信息，但占用更多内存
        /// - 禁用：节省内存，适合生产环境
        public let enableDetailedLogging: Bool
        
        /// 是否启用统计分析
        ///
        /// **性能考虑**：
        /// - 启用：实时计算统计信息，略微影响性能
        /// - 禁用：仅在需要时计算，节省 CPU
        public let enableStatistics: Bool
        
        public init(
            maxHistoryCount: Int = 1000,
            enableSmartFiltering: Bool = true,
            minimumDuration: TimeInterval = 2.0,
            enableDetailedLogging: Bool = true,
            enableStatistics: Bool = true
        ) {
            self.maxHistoryCount = maxHistoryCount
            self.enableSmartFiltering = enableSmartFiltering
            self.minimumDuration = minimumDuration
            self.enableDetailedLogging = enableDetailedLogging
            self.enableStatistics = enableStatistics
        }
        
        /// 默认配置
        public static let `default` = Configuration()
        
        /// 高性能配置（减少内存使用和计算）
        public static let performance = Configuration(
            maxHistoryCount: 500,
            enableSmartFiltering: false,
            enableDetailedLogging: false,
            enableStatistics: false
        )
        
        /// 详细分析配置（最大化信息收集）
        public static let detailed = Configuration(
            maxHistoryCount: 2000,
            enableSmartFiltering: true,
            minimumDuration: 1.0,
            enableDetailedLogging: true,
            enableStatistics: true
        )
    }
    
    // MARK: - Properties
    
    /// 追踪配置
    public let configuration: Configuration
    
    /// 变化历史记录（环形缓冲区）
    ///
    /// **为什么使用数组**：
    /// - 简单高效的环形缓冲区实现
    /// - 支持快速的顺序访问
    /// - 易于实现时间范围查询
    private var changeHistory: [NetworkChangeRecord] = []
    
    /// 当前网络路径
    private var currentPath: NetworkPath?
    
    /// 上次记录的时间
    private var lastRecordTime: Date?
    
    /// 统计信息缓存
    private var statistics: NetworkChangeStatistics?
    
    /// 线程安全队列
    ///
    /// **为什么使用专用队列**：
    /// - 保护内部状态的线程安全
    /// - 避免数据竞争
    /// - 使用 utility QoS 平衡性能和电量
    private let queue = DispatchQueue(label: "NetworkChangeTracker", qos: .utility)
    
    // MARK: - Initialization

    /// 初始化网络变化追踪器
    ///
    /// - Parameter configuration: 追踪配置
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        // 预分配容量以提高性能
        self.changeHistory.reserveCapacity(configuration.maxHistoryCount)
    }

    // MARK: - Public Methods

    /// 记录网络路径变化
    ///
    /// **主要的变化记录方法**，由网络监听器调用
    ///
    /// **线程安全**：可以在任意线程调用
    /// **异步执行**：在内部队列异步处理，不阻塞调用线程
    ///
    /// **处理流程**：
    /// 1. 智能过滤（如果启用）
    /// 2. 创建变化记录
    /// 3. 添加到环形缓冲区
    /// 4. 更新统计信息
    ///
    /// - Parameters:
    ///   - newPath: 新的网络路径
    ///   - previousPath: 之前的网络路径
    public func recordPathChange(_ newPath: NetworkPath, previousPath: NetworkPath?) {
        queue.async { [weak self] in
            self?._recordPathChange(newPath, previousPath: previousPath)
        }
    }

    /// 获取变化历史
    ///
    /// **线程安全**：使用 sync 确保读取一致性
    ///
    /// - Parameter count: 获取的记录数量，nil 表示获取全部
    /// - Returns: 变化记录数组
    public func getChangeHistory(count: Int? = nil) -> [NetworkChangeRecord] {
        return queue.sync {
            if let count = count {
                return Array(changeHistory.suffix(count))
            } else {
                return changeHistory
            }
        }
    }

    /// 获取指定时间范围内的变化记录
    ///
    /// **用途**：分析特定时间段的网络行为
    ///
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    /// - Returns: 时间范围内的变化记录
    public func getChangeHistory(from startTime: Date, to endTime: Date) -> [NetworkChangeRecord] {
        return queue.sync {
            return changeHistory.filter { record in
                record.timestamp >= startTime && record.timestamp <= endTime
            }
        }
    }

    /// 获取统计信息
    ///
    /// **性能优化**：
    /// - 如果启用统计，返回缓存的统计信息
    /// - 如果禁用统计，生成基础统计信息
    ///
    /// - Returns: 网络变化统计信息
    public func getStatistics() -> NetworkChangeStatistics {
        return queue.sync {
            if configuration.enableStatistics {
                updateStatistics()
                return statistics ?? NetworkChangeStatistics.empty
            } else {
                return generateBasicStatistics()
            }
        }
    }

    /// 清除历史记录
    ///
    /// **用途**：
    /// - 重置追踪器状态
    /// - 释放内存
    /// - 开始新的追踪周期
    public func clearHistory() {
        queue.async { [weak self] in
            self?.changeHistory.removeAll()
            self?.statistics = nil
            self?.lastRecordTime = nil
            self?.currentPath = nil
        }
    }

    /// 检测频繁断连模式
    ///
    /// **用途**：识别网络不稳定的模式
    ///
    /// **检测逻辑**：
    /// - 分析最近的断连事件
    /// - 计算断连频率
    /// - 识别周期性断连
    ///
    /// - Returns: 是否检测到频繁断连
    public func detectFrequentDisconnections() -> Bool {
        return queue.sync {
            let recentHistory = Array(changeHistory.suffix(20))
            let disconnections = recentHistory.filter { $0.changeType == .disconnected }

            // 如果最近20次变化中有5次以上断连，认为是频繁断连
            return disconnections.count >= 5
        }
    }

    /// 检测质量下降模式
    ///
    /// **用途**：识别网络质量持续下降的趋势
    ///
    /// - Returns: 是否检测到质量下降
    public func detectQualityDegradation() -> Bool {
        return queue.sync {
            let recentHistory = Array(changeHistory.suffix(10))
            let qualityChanges = recentHistory.filter {
                $0.changeType == .qualityDegraded || $0.changeType == .qualityImproved
            }

            let degradations = qualityChanges.filter { $0.changeType == .qualityDegraded }

            // 如果质量变化中有70%以上是下降，认为是质量下降趋势
            return qualityChanges.count > 0 &&
                   Double(degradations.count) / Double(qualityChanges.count) > 0.7
        }
    }

    // MARK: - Private Implementation

    /// 内部记录路径变化方法
    ///
    /// **执行环境**：内部队列（已在队列中）
    ///
    /// - Parameters:
    ///   - newPath: 新的网络路径
    ///   - previousPath: 之前的网络路径
    private func _recordPathChange(_ newPath: NetworkPath, previousPath: NetworkPath?) {
        let now = Date()

        // 智能过滤：检查是否应该记录这次变化
        if configuration.enableSmartFiltering {
            if shouldFilterChange(newPath, previousPath: previousPath, timestamp: now) {
                return
            }
        }

        // 创建变化记录
        let changeRecord = createChangeRecord(newPath, previousPath: previousPath, timestamp: now)

        // 添加到历史记录（环形缓冲区）
        addToHistory(changeRecord)

        // 更新当前状态
        currentPath = newPath
        lastRecordTime = now

        // 更新统计信息
        if configuration.enableStatistics {
            updateStatistics()
        }
    }

    /// 判断是否应该过滤此次变化
    ///
    /// **智能过滤逻辑**：
    /// 1. 过滤掉持续时间过短的变化（网络抖动）
    /// 2. 过滤掉相同状态的重复记录
    /// 3. 保留重要的状态变化（可用性、质量等级变化）
    ///
    /// **为什么需要智能过滤**：
    /// - 减少噪音数据，提高分析准确性
    /// - 节省存储空间
    /// - 避免频繁的统计计算
    ///
    /// - Parameters:
    ///   - newPath: 新路径
    ///   - previousPath: 之前路径
    ///   - timestamp: 时间戳
    /// - Returns: 是否应该过滤
    private func shouldFilterChange(_ newPath: NetworkPath, previousPath: NetworkPath?, timestamp: Date) -> Bool {
        // 如果没有之前的路径，不过滤（首次记录）
        guard let previousPath = previousPath else { return false }

        // 如果是重要变化，不过滤
        if isSignificantChange(newPath, previousPath: previousPath) {
            return false
        }

        // 检查持续时间过滤
        if let lastTime = lastRecordTime {
            let duration = timestamp.timeIntervalSince(lastTime)
            if duration < configuration.minimumDuration {
                return true  // 过滤掉持续时间过短的变化
            }
        }

        return false
    }

    /// 判断是否为重要变化
    ///
    /// **重要变化定义**：
    /// - 网络可用性变化（连接/断开）
    /// - 连接类型变化（WiFi ↔ 蜂窝）
    /// - 网络质量等级变化
    /// - 成本状态变化（免费 ↔ 昂贵）
    /// - 约束状态变化（无限制 ↔ 受限）
    ///
    /// - Parameters:
    ///   - newPath: 新路径
    ///   - previousPath: 之前路径
    /// - Returns: 是否为重要变化
    private func isSignificantChange(_ newPath: NetworkPath, previousPath: NetworkPath) -> Bool {
        // 网络可用性变化
        if newPath.isNetworkAvailable != previousPath.isNetworkAvailable {
            return true
        }

        // 连接类型变化
        if newPath.connectionType != previousPath.connectionType {
            return true
        }

        // 网络质量等级变化
        if newPath.quality != previousPath.quality {
            return true
        }

        // 成本状态变化
        if newPath.isExpensive != previousPath.isExpensive {
            return true
        }

        // 约束状态变化
        if newPath.isConstrained != previousPath.isConstrained {
            return true
        }

        return false
    }

    /// 创建变化记录
    ///
    /// - Parameters:
    ///   - newPath: 新路径
    ///   - previousPath: 之前路径
    ///   - timestamp: 时间戳
    /// - Returns: 变化记录
    private func createChangeRecord(_ newPath: NetworkPath, previousPath: NetworkPath?, timestamp: Date) -> NetworkChangeRecord {
        let changeType = determineChangeType(newPath, previousPath: previousPath)
        let duration = calculateDuration(previousPath: previousPath, timestamp: timestamp)

        var details: [String: String] = [:]

        if configuration.enableDetailedLogging {
            details = createDetailedChangeInfo(newPath, previousPath: previousPath)
        }

        return NetworkChangeRecord(
            id: UUID(),
            timestamp: timestamp,
            changeType: changeType,
            newPath: newPath,
            previousPath: previousPath,
            duration: duration,
            details: details
        )
    }

    /// 确定变化类型
    ///
    /// **分类逻辑**：
    /// 1. 首次记录 → initial
    /// 2. 可用性变化 → connected/disconnected
    /// 3. 连接类型变化 → connectionTypeChanged
    /// 4. 质量变化 → qualityImproved/qualityDegraded
    /// 5. 属性变化 → propertiesChanged
    /// 6. 其他 → statusUpdate
    ///
    /// - Parameters:
    ///   - newPath: 新路径
    ///   - previousPath: 之前路径
    /// - Returns: 变化类型
    private func determineChangeType(_ newPath: NetworkPath, previousPath: NetworkPath?) -> NetworkChangeType {
        guard let previousPath = previousPath else {
            return .initial
        }

        // 网络可用性变化（最高优先级）
        if !previousPath.isNetworkAvailable && newPath.isNetworkAvailable {
            return .connected
        } else if previousPath.isNetworkAvailable && !newPath.isNetworkAvailable {
            return .disconnected
        }

        // 连接类型变化
        if previousPath.connectionType != newPath.connectionType {
            return .connectionTypeChanged
        }

        // 质量变化
        if previousPath.quality != newPath.quality {
            if newPath.quality > previousPath.quality {
                return .qualityImproved
            } else {
                return .qualityDegraded
            }
        }

        // 成本或约束变化
        if previousPath.isExpensive != newPath.isExpensive ||
           previousPath.isConstrained != newPath.isConstrained {
            return .propertiesChanged
        }

        return .statusUpdate
    }

    /// 计算持续时间
    ///
    /// - Parameters:
    ///   - previousPath: 之前路径
    ///   - timestamp: 当前时间戳
    /// - Returns: 持续时间（秒）
    private func calculateDuration(previousPath: NetworkPath?, timestamp: Date) -> TimeInterval? {
        guard previousPath != nil, let lastTime = lastRecordTime else {
            return nil
        }

        return timestamp.timeIntervalSince(lastTime)
    }

    /// 创建详细变化信息
    ///
    /// **包含信息**：
    /// - 新旧状态对比
    /// - 各项属性变化标记
    /// - 质量评估结果
    ///
    /// - Parameters:
    ///   - newPath: 新路径
    ///   - previousPath: 之前路径
    /// - Returns: 详细信息字典
    private func createDetailedChangeInfo(_ newPath: NetworkPath, previousPath: NetworkPath?) -> [String: String] {
        var details: [String: String] = [:]

        // 基本路径信息
        details["newStatus"] = String(describing: newPath.status)
        details["newConnectionType"] = newPath.connectionType.rawValue
        details["newQuality"] = newPath.quality.rawValue
        details["newIsExpensive"] = String(newPath.isExpensive)
        details["newIsConstrained"] = String(newPath.isConstrained)

        if let previousPath = previousPath {
            details["previousStatus"] = String(describing: previousPath.status)
            details["previousConnectionType"] = previousPath.connectionType.rawValue
            details["previousQuality"] = previousPath.quality.rawValue
            details["previousIsExpensive"] = String(previousPath.isExpensive)
            details["previousIsConstrained"] = String(previousPath.isConstrained)

            // 变化摘要
            details["availabilityChanged"] = String(newPath.isNetworkAvailable != previousPath.isNetworkAvailable)
            details["connectionTypeChanged"] = String(newPath.connectionType != previousPath.connectionType)
            details["qualityChanged"] = String(newPath.quality != previousPath.quality)
            details["costChanged"] = String(newPath.isExpensive != previousPath.isExpensive)
            details["constraintChanged"] = String(newPath.isConstrained != previousPath.isConstrained)
        }

        // 质量评估
        let qualityAssessment = NetworkQualityAssessor.detailedAssessment(from: newPath)
        details["qualityScore"] = String(format: "%.2f", qualityAssessment.totalScore)

        return details
    }

    /// 添加记录到历史（环形缓冲区）
    ///
    /// **环形缓冲区实现**：
    /// - 超出最大数量时移除最旧的记录
    /// - 保持固定的内存占用
    /// - 确保最新数据始终可用
    ///
    /// - Parameter record: 变化记录
    private func addToHistory(_ record: NetworkChangeRecord) {
        changeHistory.append(record)

        // 环形缓冲区：超出最大数量时移除最旧的记录
        if changeHistory.count > configuration.maxHistoryCount {
            changeHistory.removeFirst(changeHistory.count - configuration.maxHistoryCount)
        }
    }

    /// 更新统计信息
    private func updateStatistics() {
        guard configuration.enableStatistics else { return }

        statistics = generateDetailedStatistics()
    }

    /// 生成详细统计信息
    ///
    /// **统计维度**：
    /// - 总变化次数
    /// - 时间跨度
    /// - 变化频率
    /// - 平均持续时间
    /// - 变化类型分布
    /// - 连接类型分布
    /// - 质量分布
    /// - 稳定性得分
    ///
    /// - Returns: 详细统计信息
    private func generateDetailedStatistics() -> NetworkChangeStatistics {
        guard !changeHistory.isEmpty else {
            return NetworkChangeStatistics.empty
        }

        let totalChanges = changeHistory.count
        let timeSpan = calculateTimeSpan()

        // 变化类型统计
        let changeTypeDistribution = Dictionary(grouping: changeHistory) { $0.changeType }
            .mapValues { $0.count }

        // 连接类型统计
        let connectionTypeDistribution = Dictionary(grouping: changeHistory) { $0.newPath.connectionType }
            .mapValues { $0.count }

        // 质量分布统计
        let qualityDistribution = Dictionary(grouping: changeHistory) { $0.newPath.quality }
            .mapValues { $0.count }

        // 计算平均持续时间
        let durations = changeHistory.compactMap { $0.duration }
        let averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)

        // 计算变化频率（次/秒）
        let changeFrequency = timeSpan > 0 ? Double(totalChanges) / timeSpan : 0

        // 稳定性分析
        let stabilityScore = calculateStabilityScore()

        return NetworkChangeStatistics(
            totalChanges: totalChanges,
            timeSpan: timeSpan,
            changeFrequency: changeFrequency,
            averageDuration: averageDuration,
            changeTypeDistribution: changeTypeDistribution,
            connectionTypeDistribution: connectionTypeDistribution,
            qualityDistribution: qualityDistribution,
            stabilityScore: stabilityScore,
            lastUpdateTime: Date()
        )
    }

    /// 生成基础统计信息
    ///
    /// **用途**：当禁用统计时提供最小化的统计信息
    ///
    /// - Returns: 基础统计信息
    private func generateBasicStatistics() -> NetworkChangeStatistics {
        return NetworkChangeStatistics(
            totalChanges: changeHistory.count,
            timeSpan: calculateTimeSpan(),
            changeFrequency: 0,
            averageDuration: 0,
            changeTypeDistribution: [:],
            connectionTypeDistribution: [:],
            qualityDistribution: [:],
            stabilityScore: 0,
            lastUpdateTime: Date()
        )
    }

    /// 计算时间跨度
    ///
    /// **计算方法**：最后一条记录时间 - 第一条记录时间
    ///
    /// - Returns: 时间跨度（秒）
    private func calculateTimeSpan() -> TimeInterval {
        guard let firstRecord = changeHistory.first,
              let lastRecord = changeHistory.last else {
            return 0
        }

        return lastRecord.timestamp.timeIntervalSince(firstRecord.timestamp)
    }

    /// 计算稳定性得分
    ///
    /// **评分维度**：
    /// 1. **变化频率**：变化越频繁，稳定性越低
    /// 2. **连接稳定性**：断连/重连次数越多，稳定性越低
    ///
    /// **得分范围**：0.0-1.0（1.0 表示完全稳定）
    ///
    /// **计算公式**：
    /// - 频率得分 = max(0, 1.0 - 变化频率 / 10.0)
    /// - 连接得分 = max(0, 1.0 - (断连+重连) / 总变化)
    /// - 综合得分 = (频率得分 + 连接得分) / 2.0
    ///
    /// - Returns: 稳定性得分
    private func calculateStabilityScore() -> Double {
        guard !changeHistory.isEmpty else { return 1.0 }

        let timeSpan = calculateTimeSpan()
        guard timeSpan > 0 else { return 1.0 }

        // 基于变化频率的稳定性
        // 假设每10秒1次变化为不稳定的阈值
        let changeFrequency = Double(changeHistory.count) / timeSpan
        let frequencyScore = max(0, 1.0 - changeFrequency / 10.0)

        // 基于变化类型的稳定性
        let disconnectionCount = changeHistory.filter { $0.changeType == .disconnected }.count
        let connectionCount = changeHistory.filter { $0.changeType == .connected }.count
        let connectionStabilityScore = max(0, 1.0 - Double(disconnectionCount + connectionCount) / Double(changeHistory.count))

        // 综合得分
        return (frequencyScore + connectionStabilityScore) / 2.0
    }
}

