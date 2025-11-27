import Foundation

// MARK: - Network Change Type

/// 网络变化类型
///
/// **用途**：标识网络状态变化的具体类型
///
/// **设计考虑**：
/// - 使用枚举确保类型安全
/// - 提供清晰的语义化命名
/// - 支持 Codable 用于数据导出
public enum NetworkChangeType: String, Codable, Equatable {
    /// 初始状态
    case initial
    
    /// 网络已连接
    case connected
    
    /// 网络已断开
    case disconnected
    
    /// 连接类型变化（WiFi ↔ 蜂窝）
    case connectionTypeChanged
    
    /// 网络质量提升
    case qualityImproved
    
    /// 网络质量下降
    case qualityDegraded
    
    /// 网络属性变化（成本、约束等）
    case propertiesChanged
    
    /// 状态更新（无重要变化）
    case statusUpdate
}

// MARK: - Network Change Record

/// 网络变化记录
///
/// **用途**：记录单次网络状态变化的完整信息
///
/// **设计理念**：
/// - 使用 struct 确保值语义和线程安全
/// - 包含完整的前后状态对比
/// - 支持详细信息扩展
public struct NetworkChangeRecord: Codable, Equatable {
    /// 唯一标识符
    public let id: UUID
    
    /// 变化时间戳
    public let timestamp: Date
    
    /// 变化类型
    public let changeType: NetworkChangeType
    
    /// 新的网络路径
    public let newPath: NetworkPath
    
    /// 之前的网络路径（可能为空）
    public let previousPath: NetworkPath?
    
    /// 持续时间（秒）
    public let duration: TimeInterval?
    
    /// 详细信息（可扩展）
    public let details: [String: String]
    
    public init(
        id: UUID = UUID(),
        timestamp: Date,
        changeType: NetworkChangeType,
        newPath: NetworkPath,
        previousPath: NetworkPath?,
        duration: TimeInterval?,
        details: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.changeType = changeType
        self.newPath = newPath
        self.previousPath = previousPath
        self.duration = duration
        self.details = details
    }
}

// MARK: - Network Change Statistics

/// 网络变化统计信息
///
/// **用途**：提供网络变化的统计分析数据
public struct NetworkChangeStatistics: Codable, Equatable {
    /// 总变化次数
    public let totalChanges: Int
    
    /// 时间跨度（秒）
    public let timeSpan: TimeInterval
    
    /// 变化频率（次/秒）
    public let changeFrequency: Double
    
    /// 平均持续时间（秒）
    public let averageDuration: TimeInterval
    
    /// 变化类型分布
    public let changeTypeDistribution: [NetworkChangeType: Int]
    
    /// 连接类型分布
    public let connectionTypeDistribution: [ConnectionType: Int]
    
    /// 质量分布
    public let qualityDistribution: [NetworkQuality: Int]
    
    /// 稳定性得分 (0.0-1.0)
    public let stabilityScore: Double
    
    /// 最后更新时间
    public let lastUpdateTime: Date
    
    /// 空统计信息
    public static var empty: NetworkChangeStatistics {
        NetworkChangeStatistics(
            totalChanges: 0,
            timeSpan: 0,
            changeFrequency: 0,
            averageDuration: 0,
            changeTypeDistribution: [:],
            connectionTypeDistribution: [:],
            qualityDistribution: [:],
            stabilityScore: 1.0,
            lastUpdateTime: Date()
        )
    }
}

