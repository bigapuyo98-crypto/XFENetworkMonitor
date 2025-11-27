import Foundation
import Network

/// 网络质量评估器
///
/// **设计目标**：提供智能的网络质量评估和分析功能
///
/// **核心功能**：
/// - 基础质量评估：基于网络路径的多维度评估
/// - 详细质量评估：提供各维度得分和优化建议
/// - 质量比较：比较两个网络路径的质量差异
/// - 历史趋势分析：分析网络质量的变化趋势
///
/// **评估维度**（按优先级）：
/// 1. 网络状态（最高优先级）- satisfied/unsatisfied/requiresConnection
/// 2. 用户约束（低数据模式）- 尊重用户意图
/// 3. 网络成本（昂贵网络）- 避免额外费用
/// 4. 接口类型（WiFi > 有线 > 蜂窝 > 其他）
/// 5. 协议支持（IPv4/IPv6/DNS）
///
/// **Why 使用 struct**：
/// - 无状态设计，所有方法都是静态的
/// - 值类型确保线程安全
/// - 轻量级，不需要实例化
public struct NetworkQualityAssessor {
    
    // MARK: - Core Assessment Method
    
    /// 评估网络质量
    ///
    /// **评估逻辑**（按优先级）：
    /// 1. 网络不可用 → poor
    /// 2. 受限网络（低数据模式）→ fair
    /// 3. 昂贵网络（蜂窝/热点）→ good
    /// 4. 其他情况（WiFi/有线）→ excellent
    ///
    /// **Why 这个优先级顺序**：
    /// - 网络状态是最基本的可用性保证
    /// - 用户约束（低数据模式）体现用户意图，应优先尊重
    /// - 网络成本影响用户费用，需要考虑
    /// - 接口类型影响速度和稳定性
    ///
    /// - Parameter path: 网络路径信息
    /// - Returns: 网络质量等级
    public static func assessQuality(from path: NetworkPath) -> NetworkQuality {
        // 1. 网络状态检查（最高优先级）
        // Why: 网络不可用时，其他因素都无意义
        guard path.status == .satisfied else {
            return .poor
        }
        
        // 2. 用户约束检查（用户意图优先）
        // Why: 用户明确开启低数据模式，应优先尊重用户意图
        if path.isConstrained {
            return .fair
        }
        
        // 3. 网络成本检查（避免额外费用）
        // Why: 昂贵网络可能产生额外费用，需要提醒用户
        if path.isExpensive {
            return .good
        }
        
        // 4. 接口类型评估
        // Why: 不同接口类型有不同的速度和稳定性特征
        return assessByConnectionType(path.connectionType)
    }
    
    /// 基于连接类型评估质量
    ///
    /// **不同连接类型的质量评估**：
    /// - WiFi: 通常免费且高速 → excellent
    /// - 有线网络: 稳定高速 → excellent
    /// - 蜂窝网络: 可能有流量限制 → good
    /// - 其他/环回: 特殊情况 → fair
    /// - 不可用: 无连接 → poor
    ///
    /// **Why WiFi 和有线都是 excellent**：
    /// - 两者都通常免费、无流量限制
    /// - 速度和稳定性都很好
    /// - 适合大文件传输和高质量媒体
    ///
    /// - Parameter connectionType: 连接类型
    /// - Returns: 基于连接类型的质量等级
    private static func assessByConnectionType(_ connectionType: ConnectionType) -> NetworkQuality {
        switch connectionType {
        case .wifi, .wiredEthernet:
            return .excellent
        case .cellular:
            return .good
        case .loopback, .other:
            return .fair
        case .unavailable:
            return .poor
        }
    }
}

// MARK: - Advanced Assessment

public extension NetworkQualityAssessor {

    /// 详细质量评估
    ///
    /// **提供更详细的质量评估信息**，包括各个维度的得分和优化建议
    ///
    /// **评估维度**：
    /// - statusScore: 网络状态得分（0.0-1.0）
    /// - constraintScore: 约束得分（0.0-1.0）
    /// - costScore: 成本得分（0.0-1.0）
    /// - typeScore: 连接类型得分（0.0-1.0）
    /// - protocolScore: 协议支持得分（0.0-1.0）
    ///
    /// **Why 使用多维度评分**：
    /// - 提供更细粒度的质量分析
    /// - 帮助开发者了解质量瓶颈在哪里
    /// - 生成针对性的优化建议
    ///
    /// - Parameter path: 网络路径信息
    /// - Returns: 详细的质量评估结果
    static func detailedAssessment(from path: NetworkPath) -> DetailedQualityAssessment {
        let statusScore = assessStatusScore(path.status)
        let constraintScore = assessConstraintScore(path.isConstrained)
        let costScore = assessCostScore(path.isExpensive)
        let typeScore = assessTypeScore(path.connectionType)
        let protocolScore = assessProtocolScore(path)

        // 计算总分（所有维度平均）
        // Why 使用平均值：每个维度同等重要，避免某个维度权重过大
        let totalScore = (statusScore + constraintScore + costScore + typeScore + protocolScore) / 5.0
        let quality = qualityFromScore(totalScore)

        return DetailedQualityAssessment(
            overallQuality: quality,
            totalScore: totalScore,
            statusScore: statusScore,
            constraintScore: constraintScore,
            costScore: costScore,
            typeScore: typeScore,
            protocolScore: protocolScore,
            recommendations: generateRecommendations(from: path, score: totalScore)
        )
    }

    /// 评估网络状态得分
    ///
    /// **状态评分标准**：
    /// - satisfied: 1.0（网络完全可用）
    /// - requiresConnection: 0.5（需要建立连接，如按需拨号）
    /// - unsatisfied: 0.0（网络不可用）
    ///
    /// - Parameter status: 网络状态
    /// - Returns: 状态得分 (0.0-1.0)
    private static func assessStatusScore(_ status: NWPath.Status) -> Double {
        switch status {
        case .satisfied:
            return 1.0
        case .requiresConnection:
            return 0.5
        case .unsatisfied:
            return 0.0
            
        @unknown default:
            return 0.0
        }
    }

    /// 评估约束得分
    ///
    /// **约束评分标准**：
    /// - 未受限: 1.0（无限制）
    /// - 受限（低数据模式）: 0.6（有限制但可用）
    ///
    /// **Why 受限是 0.6 而不是更低**：
    /// - 低数据模式是用户主动选择，不是网络问题
    /// - 网络仍然可用，只是应用应该减少数据使用
    ///
    /// - Parameter isConstrained: 是否受限
    /// - Returns: 约束得分 (0.0-1.0)
    private static func assessConstraintScore(_ isConstrained: Bool) -> Double {
        return isConstrained ? 0.6 : 1.0
    }

    /// 评估成本得分
    ///
    /// **成本评分标准**：
    /// - 免费网络: 1.0（无额外费用）
    /// - 昂贵网络: 0.7（可能产生费用）
    ///
    /// **Why 昂贵网络是 0.7**：
    /// - 网络仍然可用且通常速度不错
    /// - 主要考虑是费用问题，不是性能问题
    ///
    /// - Parameter isExpensive: 是否昂贵
    /// - Returns: 成本得分 (0.0-1.0)
    private static func assessCostScore(_ isExpensive: Bool) -> Double {
        return isExpensive ? 0.7 : 1.0
    }

    /// 评估连接类型得分
    ///
    /// **连接类型评分标准**：
    /// - WiFi: 1.0（最佳，免费高速）
    /// - 有线网络: 0.95（稳定但可能不便携）
    /// - 蜂窝网络: 0.8（移动性好但可能有流量限制）
    /// - 环回: 0.5（本地连接，特殊用途）
    /// - 其他: 0.4（未知类型，不确定性高）
    /// - 不可用: 0.0（无连接）
    ///
    /// **Why 这些分数**：
    /// - WiFi 最高因为免费、高速、稳定
    /// - 有线略低因为便携性差
    /// - 蜂窝较低因为可能有流量费用
    ///
    /// - Parameter connectionType: 连接类型
    /// - Returns: 类型得分 (0.0-1.0)
    private static func assessTypeScore(_ connectionType: ConnectionType) -> Double {
        switch connectionType {
        case .wifi:
            return 1.0
        case .wiredEthernet:
            return 0.95
        case .cellular:
            return 0.8
        case .loopback:
            return 0.5
        case .other:
            return 0.4
        case .unavailable:
            return 0.0
        }
    }

    /// 评估协议支持得分
    ///
    /// **协议支持评分标准**：
    /// - 基础得分: 0.5
    /// - 支持 IPv6: +0.2
    /// - 支持 IPv4: +0.2
    /// - 支持 DNS: +0.1
    ///
    /// **Why 这个评分方式**：
    /// - IPv4 和 IPv6 同等重要（各 0.2）
    /// - DNS 支持是基础功能（0.1）
    /// - 最高分 1.0（全部支持）
    ///
    /// - Parameter path: 网络路径
    /// - Returns: 协议得分 (0.0-1.0)
    private static func assessProtocolScore(_ path: NetworkPath) -> Double {
        var score = 0.5  // 基础得分

        if path.supportsIPv6 {
            score += 0.2
        }

        if path.supportsIPv4 {
            score += 0.2
        }

        if path.supportsDNS {
            score += 0.1
        }

        return min(score, 1.0)
    }

    /// 从得分转换为质量等级
    ///
    /// **分级标准**：
    /// - 0.85-1.0: excellent（优秀）
    /// - 0.65-0.85: good（良好）
    /// - 0.35-0.65: fair（一般）
    /// - 0.0-0.35: poor（差）
    ///
    /// **Why 这些阈值**：
    /// - 0.85 以上才算优秀，确保高质量标准
    /// - 0.65-0.85 是良好，可以正常使用
    /// - 0.35-0.65 是一般，需要注意数据使用
    /// - 0.35 以下是差，建议等待更好的网络
    ///
    /// - Parameter score: 综合得分 (0.0-1.0)
    /// - Returns: 对应的质量等级
    private static func qualityFromScore(_ score: Double) -> NetworkQuality {
        switch score {
        case 0.85...1.0:
            return .excellent
        case 0.65..<0.85:
            return .good
        case 0.35..<0.65:
            return .fair
        default:
            return .poor
        }
    }

    /// 生成网络优化建议
    ///
    /// **建议类型**：
    /// - 网络状态建议：检查网络连接
    /// - 约束建议：关闭低数据模式
    /// - 成本建议：切换到 WiFi
    /// - 连接类型建议：优化连接方式
    /// - 协议支持建议：检查网络配置
    /// - 综合得分建议：整体优化方向
    ///
    /// **Why 提供多维度建议**：
    /// - 帮助用户快速定位问题
    /// - 提供可操作的优化方案
    /// - 提升用户体验
    ///
    /// - Parameters:
    ///   - path: 网络路径
    ///   - score: 综合得分
    /// - Returns: 优化建议数组
    private static func generateRecommendations(from path: NetworkPath, score: Double) -> [String] {
        var recommendations: [String] = []

        // 网络状态建议
        if path.status != .satisfied {
            recommendations.append("检查网络连接，确保设备已连接到可用网络")
        }

        // 约束建议
        if path.isConstrained {
            recommendations.append("当前处于低数据模式，考虑关闭以获得更好的网络体验")
        }

        // 成本建议
        if path.isExpensive {
            recommendations.append("当前使用昂贵网络（蜂窝数据），建议连接 WiFi 以节省流量")
        }

        // 连接类型建议
        switch path.connectionType {
        case .cellular:
            recommendations.append("建议连接 WiFi 网络以获得更稳定的连接和更快的速度")
        case .other, .loopback:
            recommendations.append("当前连接类型可能不稳定，建议切换到 WiFi 或蜂窝网络")
        case .unavailable:
            recommendations.append("网络不可用，请检查网络设置或联系网络服务提供商")
        default:
            break
        }

        // 协议支持建议
        if !path.supportsIPv6 && !path.supportsIPv4 {
            recommendations.append("网络协议支持有限，可能影响某些服务的访问")
        }

        // 综合得分建议
        if score < 0.5 {
            recommendations.append("网络质量较差，建议检查网络配置或更换网络环境")
        } else if score < 0.8 {
            recommendations.append("网络质量一般，可以考虑优化网络设置以提升体验")
        }

        return recommendations
    }
}

// MARK: - Quality Comparison

public extension NetworkQualityAssessor {

    /// 比较两个网络路径的质量
    ///
    /// **比较维度**：
    /// - 整体质量等级
    /// - 详细得分（总分和各维度得分）
    /// - 哪个网络更好
    /// - 得分差异
    /// - 针对性建议
    ///
    /// **Why 提供质量比较**：
    /// - 帮助应用选择最佳网络
    /// - 支持多网络环境下的智能切换
    /// - 提供决策依据
    ///
    /// - Parameters:
    ///   - path1: 第一个网络路径
    ///   - path2: 第二个网络路径
    /// - Returns: 质量比较结果
    static func compareQuality(_ path1: NetworkPath, _ path2: NetworkPath) -> QualityComparison {
        let quality1 = assessQuality(from: path1)
        let quality2 = assessQuality(from: path2)

        let assessment1 = detailedAssessment(from: path1)
        let assessment2 = detailedAssessment(from: path2)

        // 确定哪个网络更好
        let betterPath: QualityComparison.BetterPath
        if assessment1.totalScore > assessment2.totalScore {
            betterPath = .first
        } else if assessment1.totalScore < assessment2.totalScore {
            betterPath = .second
        } else {
            betterPath = .equal
        }

        return QualityComparison(
            path1Quality: quality1,
            path2Quality: quality2,
            path1Score: assessment1.totalScore,
            path2Score: assessment2.totalScore,
            betterPath: betterPath,
            scoreDifference: abs(assessment1.totalScore - assessment2.totalScore),
            recommendations: generateComparisonRecommendations(assessment1, assessment2)
        )
    }

    /// 生成比较建议
    ///
    /// **建议内容**：
    /// - 整体质量比较
    /// - 具体维度差异分析
    /// - 选择建议
    ///
    /// - Parameters:
    ///   - assessment1: 第一个路径的详细评估
    ///   - assessment2: 第二个路径的详细评估
    /// - Returns: 比较建议数组
    private static func generateComparisonRecommendations(
        _ assessment1: DetailedQualityAssessment,
        _ assessment2: DetailedQualityAssessment
    ) -> [String] {
        var recommendations: [String] = []

        let scoreDiff = assessment1.totalScore - assessment2.totalScore

        // 整体质量比较
        if abs(scoreDiff) < 0.1 {
            recommendations.append("两个网络质量相近，可以根据具体需求选择")
        } else if scoreDiff > 0 {
            recommendations.append("第一个网络质量更好，建议优先使用")
        } else {
            recommendations.append("第二个网络质量更好，建议优先使用")
        }

        // 具体维度比较
        if assessment1.statusScore != assessment2.statusScore {
            let better = assessment1.statusScore > assessment2.statusScore ? "第一个" : "第二个"
            recommendations.append("\(better)网络的连接状态更稳定")
        }

        if assessment1.costScore != assessment2.costScore {
            let better = assessment1.costScore > assessment2.costScore ? "第一个" : "第二个"
            recommendations.append("\(better)网络的使用成本更低")
        }

        if assessment1.typeScore != assessment2.typeScore {
            let better = assessment1.typeScore > assessment2.typeScore ? "第一个" : "第二个"
            recommendations.append("\(better)网络的连接类型更优")
        }

        return recommendations
    }
}

// MARK: - Historical Analysis

public extension NetworkQualityAssessor {

    /// 分析网络质量历史趋势
    ///
    /// **分析内容**：
    /// - 统计信息（样本数、平均分、最高分、最低分）
    /// - 质量趋势（improving/stable/declining）
    /// - 质量分布（各等级的占比）
    /// - 变化点识别（质量发生变化的时间点）
    /// - 趋势建议
    ///
    /// **Why 提供趋势分析**：
    /// - 了解网络质量的长期表现
    /// - 识别网络质量的变化模式
    /// - 预测未来网络质量
    /// - 提供优化建议
    ///
    /// - Parameter pathHistory: 历史网络路径数组
    /// - Returns: 质量趋势分析结果
    static func analyzeQualityTrend(_ pathHistory: [NetworkPath]) -> QualityTrendAnalysis {
        guard !pathHistory.isEmpty else {
            return QualityTrendAnalysis.empty
        }

        let qualityHistory = pathHistory.map { assessQuality(from: $0) }
        let scoreHistory = pathHistory.map { detailedAssessment(from: $0).totalScore }

        // 计算统计信息
        let averageScore = scoreHistory.reduce(0, +) / Double(scoreHistory.count)
        let maxScore = scoreHistory.max() ?? 0
        let minScore = scoreHistory.min() ?? 0

        // 计算趋势
        let trend = calculateTrend(scoreHistory)

        // 统计质量分布
        let qualityDistribution = Dictionary(grouping: qualityHistory) { $0 }
            .mapValues { $0.count }

        // 识别质量变化点
        let changePoints = identifyQualityChangePoints(qualityHistory)

        return QualityTrendAnalysis(
            totalSamples: pathHistory.count,
            averageScore: averageScore,
            maxScore: maxScore,
            minScore: minScore,
            trend: trend,
            qualityDistribution: qualityDistribution,
            changePoints: changePoints,
            recommendations: generateTrendRecommendations(trend, qualityDistribution, pathHistory.count)
        )
    }

    /// 计算质量趋势
    ///
    /// **使用线性回归计算质量变化趋势**
    ///
    /// **趋势判断标准**：
    /// - 斜率 > 0.01: improving（上升趋势）
    /// - 斜率 < -0.01: declining（下降趋势）
    /// - 其他: stable（稳定）
    ///
    /// **Why 使用线性回归**：
    /// - 简单有效的趋势分析方法
    /// - 能够过滤短期波动
    /// - 反映长期趋势
    ///
    /// - Parameter scores: 得分历史数组
    /// - Returns: 趋势类型
    private static func calculateTrend(_ scores: [Double]) -> QualityTrend {
        guard scores.count >= 2 else { return .stable }

        let n = Double(scores.count)
        let x = Array(0..<scores.count).map { Double($0) }
        let y = scores

        // 计算线性回归斜率
        // 公式: slope = (n * Σ(xy) - Σx * Σy) / (n * Σ(x²) - (Σx)²)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)

        // 根据斜率判断趋势
        if slope > 0.01 {
            return .improving
        } else if slope < -0.01 {
            return .declining
        } else {
            return .stable
        }
    }

    /// 识别质量变化点
    ///
    /// **识别网络质量发生显著变化的时间点**
    ///
    /// **Why 识别变化点**：
    /// - 帮助定位网络质量突变的时间
    /// - 分析变化原因
    /// - 预测未来变化
    ///
    /// - Parameter qualityHistory: 质量历史数组
    /// - Returns: 变化点索引数组
    private static func identifyQualityChangePoints(_ qualityHistory: [NetworkQuality]) -> [Int] {
        var changePoints: [Int] = []

        for i in 1..<qualityHistory.count {
            if qualityHistory[i] != qualityHistory[i-1] {
                changePoints.append(i)
            }
        }

        return changePoints
    }

    /// 生成趋势建议
    ///
    /// **建议类型**：
    /// - 趋势建议：基于整体趋势
    /// - 分布建议：基于质量分布
    ///
    /// - Parameters:
    ///   - trend: 质量趋势
    ///   - distribution: 质量分布
    ///   - totalSamples: 总样本数
    /// - Returns: 趋势建议数组
    private static func generateTrendRecommendations(
        _ trend: QualityTrend,
        _ distribution: [NetworkQuality: Int],
        _ totalSamples: Int
    ) -> [String] {
        var recommendations: [String] = []

        // 趋势建议
        switch trend {
        case .improving:
            recommendations.append("网络质量呈上升趋势，当前网络环境良好")
        case .declining:
            recommendations.append("网络质量呈下降趋势，建议检查网络环境或设备设置")
        case .stable:
            recommendations.append("网络质量保持稳定")
        }

        // 基于质量分布的建议
        let poorPercentage = Double(distribution[.poor] ?? 0) / Double(totalSamples)

        if poorPercentage > 0.3 {
            recommendations.append("网络质量差的时间占比较高（\(Int(poorPercentage * 100))%），建议优化网络环境")
        }

        let excellentPercentage = Double(distribution[.excellent] ?? 0) / Double(totalSamples)
        if excellentPercentage > 0.7 {
            recommendations.append("网络质量优秀的时间占比很高（\(Int(excellentPercentage * 100))%），网络环境良好")
        }

        return recommendations
    }
}

