import Foundation

/// 网络质量等级枚举
///
/// 基于网络状态、连接类型、成本和约束条件综合评估网络质量
/// 帮助应用根据网络质量调整行为策略
///
/// **评估维度**：
/// - 网络可用性（最高优先级）
/// - 用户数据使用偏好（低数据模式）
/// - 网络成本（蜂窝网络 vs WiFi）
/// - 连接稳定性和速度
public enum NetworkQuality: String, CaseIterable, Codable {
    /// 网络质量差 - 网络不可用或严重受限
    case poor = "poor"
    
    /// 网络质量一般 - 网络可用但有明显限制
    case fair = "fair"
    
    /// 网络质量良好 - 网络可用且基本满足需求
    case good = "good"
    
    /// 网络质量优秀 - 网络状态最佳，无明显限制
    case excellent = "excellent"
}

// MARK: - 数值表示

public extension NetworkQuality {
    /// 质量等级的数值表示（0-100）
    ///
    /// **用途**：便于进行数值比较和统计分析
    /// **取值范围**：0（最差）到 100（最好）
    var score: Int {
        switch self {
        case .poor:
            return 0
        case .fair:
            return 40
        case .good:
            return 70
        case .excellent:
            return 100
        }
    }
    
    /// 从数值创建网络质量等级
    ///
    /// **分级标准**：
    /// - 0-25: poor
    /// - 26-55: fair  
    /// - 56-85: good
    /// - 86-100: excellent
    ///
    /// - Parameter score: 质量分数（0-100）
    init(score: Int) {
        let clampedScore = max(0, min(100, score))
        switch clampedScore {
        case 0...25:
            self = .poor
        case 26...55:
            self = .fair
        case 56...85:
            self = .good
        default:
            self = .excellent
        }
    }
}

// MARK: - 显示和描述

public extension NetworkQuality {
    /// 用户友好的显示名称
    var displayName: String {
        switch self {
        case .poor:
            return "差"
        case .fair:
            return "一般"
        case .good:
            return "良好"
        case .excellent:
            return "优秀"
        }
    }
    
    /// 详细描述信息
    var description: String {
        switch self {
        case .poor:
            return "网络质量差，建议等待更好的网络环境"
        case .fair:
            return "网络质量一般，建议减少数据使用"
        case .good:
            return "网络质量良好，可以正常使用"
        case .excellent:
            return "网络质量优秀，可以进行高质量数据传输"
        }
    }
    
    /// 建议的应用行为
    var recommendedBehavior: String {
        switch self {
        case .poor:
            return "启用离线模式，暂停非必要的网络请求"
        case .fair:
            return "启用数据节省模式，降低媒体质量"
        case .good:
            return "正常使用，适当限制大文件传输"
        case .excellent:
            return "无限制使用，可进行高质量媒体传输"
        }
    }
}

// MARK: - 比较操作

extension NetworkQuality: Comparable {
    /// 网络质量比较
    ///
    /// **比较依据**：基于 score 属性进行数值比较
    /// **用途**：判断网络质量是否改善或恶化
    public static func < (lhs: NetworkQuality, rhs: NetworkQuality) -> Bool {
        return lhs.score < rhs.score
    }
}

// MARK: - 质量判断辅助方法

public extension NetworkQuality {
    /// 是否为可接受的网络质量（fair 及以上）
    ///
    /// **用途**：快速判断是否可以进行基本的网络操作
    var isAcceptable: Bool {
        return self != .poor
    }
    
    /// 是否为高质量网络（good 及以上）
    ///
    /// **用途**：判断是否可以进行高质量媒体传输
    var isHighQuality: Bool {
        return self == .good || self == .excellent
    }
    
    /// 是否建议启用数据节省模式
    ///
    /// **判断依据**：fair 及以下质量建议节省数据
    var shouldEnableDataSaving: Bool {
        return self == .poor || self == .fair
    }
}