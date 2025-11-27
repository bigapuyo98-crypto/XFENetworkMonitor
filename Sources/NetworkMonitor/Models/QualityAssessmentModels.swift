import Foundation

// MARK: - Detailed Quality Assessment

/// 详细质量评估结果
///
/// **包含内容**：
/// - 整体质量等级
/// - 总分和各维度得分
/// - 优化建议
///
/// **Why 使用 struct**：
/// - 值类型确保数据不可变
/// - 线程安全
/// - 易于传递和存储
public struct DetailedQualityAssessment: Equatable, Codable {
    /// 整体质量等级
    public let overallQuality: NetworkQuality
    
    /// 总分（0.0-1.0）
    public let totalScore: Double
    
    /// 网络状态得分（0.0-1.0）
    public let statusScore: Double
    
    /// 约束得分（0.0-1.0）
    public let constraintScore: Double
    
    /// 成本得分（0.0-1.0）
    public let costScore: Double
    
    /// 连接类型得分（0.0-1.0）
    public let typeScore: Double
    
    /// 协议支持得分（0.0-1.0）
    public let protocolScore: Double
    
    /// 优化建议
    public let recommendations: [String]
    
    public init(
        overallQuality: NetworkQuality,
        totalScore: Double,
        statusScore: Double,
        constraintScore: Double,
        costScore: Double,
        typeScore: Double,
        protocolScore: Double,
        recommendations: [String]
    ) {
        self.overallQuality = overallQuality
        self.totalScore = totalScore
        self.statusScore = statusScore
        self.constraintScore = constraintScore
        self.costScore = costScore
        self.typeScore = typeScore
        self.protocolScore = protocolScore
        self.recommendations = recommendations
    }
}

// MARK: - Quality Comparison

/// 质量比较结果
///
/// **包含内容**：
/// - 两个网络的质量等级和得分
/// - 哪个网络更好
/// - 得分差异
/// - 比较建议
public struct QualityComparison: Equatable, Codable {
    /// 第一个网络的质量等级
    public let path1Quality: NetworkQuality
    
    /// 第二个网络的质量等级
    public let path2Quality: NetworkQuality
    
    /// 第一个网络的得分
    public let path1Score: Double
    
    /// 第二个网络的得分
    public let path2Score: Double
    
    /// 哪个网络更好
    public let betterPath: BetterPath
    
    /// 得分差异（绝对值）
    public let scoreDifference: Double
    
    /// 比较建议
    public let recommendations: [String]
    
    /// 哪个网络更好的枚举
    public enum BetterPath: String, Codable {
        case first = "first"
        case second = "second"
        case equal = "equal"
    }
    
    public init(
        path1Quality: NetworkQuality,
        path2Quality: NetworkQuality,
        path1Score: Double,
        path2Score: Double,
        betterPath: BetterPath,
        scoreDifference: Double,
        recommendations: [String]
    ) {
        self.path1Quality = path1Quality
        self.path2Quality = path2Quality
        self.path1Score = path1Score
        self.path2Score = path2Score
        self.betterPath = betterPath
        self.scoreDifference = scoreDifference
        self.recommendations = recommendations
    }
}

// MARK: - Quality Trend

/// 质量趋势枚举
///
/// **趋势类型**：
/// - improving: 质量上升
/// - stable: 质量稳定
/// - declining: 质量下降
public enum QualityTrend: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}

// MARK: - Quality Trend Analysis

/// 质量趋势分析结果
///
/// **包含内容**：
/// - 统计信息（样本数、平均分、最高分、最低分）
/// - 质量趋势
/// - 质量分布
/// - 变化点
/// - 趋势建议
public struct QualityTrendAnalysis: Equatable, Codable {
    /// 总样本数
    public let totalSamples: Int
    
    /// 平均得分
    public let averageScore: Double
    
    /// 最高得分
    public let maxScore: Double
    
    /// 最低得分
    public let minScore: Double
    
    /// 质量趋势
    public let trend: QualityTrend
    
    /// 质量分布（各等级的数量）
    public let qualityDistribution: [NetworkQuality: Int]
    
    /// 变化点索引数组
    public let changePoints: [Int]
    
    /// 趋势建议
    public let recommendations: [String]

    public init(
        totalSamples: Int,
        averageScore: Double,
        maxScore: Double,
        minScore: Double,
        trend: QualityTrend,
        qualityDistribution: [NetworkQuality: Int],
        changePoints: [Int],
        recommendations: [String]
    ) {
        self.totalSamples = totalSamples
        self.averageScore = averageScore
        self.maxScore = maxScore
        self.minScore = minScore
        self.trend = trend
        self.qualityDistribution = qualityDistribution
        self.changePoints = changePoints
        self.recommendations = recommendations
    }

    /// 空的趋势分析结果（用于空历史数据）
    public static var empty: QualityTrendAnalysis {
        return QualityTrendAnalysis(
            totalSamples: 0,
            averageScore: 0,
            maxScore: 0,
            minScore: 0,
            trend: .stable,
            qualityDistribution: [:],
            changePoints: [],
            recommendations: ["没有足够的历史数据进行趋势分析"]
        )
    }
}

