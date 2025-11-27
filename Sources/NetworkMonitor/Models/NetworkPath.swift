import Foundation
import Network

/// 网络路径信息结构体
///
/// 封装了网络连接的完整状态信息，包括连接类型、状态、成本和协议支持等
/// 基于 NWPath 进行封装，提供更友好的 Swift API
///
/// **设计原则**：
/// - 值类型（struct）确保线程安全和数据一致性
/// - 不可变属性避免意外修改
/// - 提供计算属性简化常用判断
/// - 支持 Codable 便于序列化和存储
public struct NetworkPath: Equatable, Codable {
    
    // MARK: - 基本属性
    
    /// 网络路径状态
    ///
    /// **状态说明**：
    /// - satisfied: 网络可用，可以进行数据传输
    /// - unsatisfied: 网络不可用
    /// - requiresConnection: 需要建立连接（如按需拨号）
    public let status: NWPath.Status
    
    /// 连接类型
    ///
    /// **类型识别**：基于主要的网络接口类型确定
    /// 如果有多个接口，优先选择速度最快的类型
    public let connectionType: ConnectionType
    
    /// 是否为昂贵网络
    ///
    /// **判断依据**：
    /// - 蜂窝网络通常被认为是昂贵的
    /// - 热点共享网络也可能是昂贵的
    /// - WiFi 和有线网络通常不昂贵
    public let isExpensive: Bool
    
    /// 是否为受限网络（低数据模式）
    ///
    /// **含义**：用户明确启用了低数据模式，应用应减少数据使用
    /// **应用策略**：降低图片质量、暂停自动更新、减少预加载等
    public let isConstrained: Bool
    
    /// 是否支持 IPv4 协议
    public let supportsIPv4: Bool
    
    /// 是否支持 IPv6 协议
    public let supportsIPv6: Bool
    
    /// 是否支持 DNS 解析
    public let supportsDNS: Bool
    
    /// 路径信息创建时间
    ///
    /// **用途**：用于追踪网络状态变化的时间线
    public let timestamp: Date
    
    // MARK: - 初始化方法
    
    /// 从 NWPath 创建 NetworkPath
    ///
    /// **转换逻辑**：
    /// - 提取主要接口类型作为连接类型
    /// - 如果没有可用接口，设置为 unavailable
    /// - 保留所有原始状态信息
    ///
    /// - Parameter nwPath: Network framework 的路径对象
    public init(nwPath: NWPath) {
        self.status = nwPath.status
        self.isExpensive = nwPath.isExpensive

        // isConstrained 在 iOS 13.0+ / macOS 10.15+ 才可用
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            self.isConstrained = nwPath.isConstrained
        } else {
            self.isConstrained = false
        }

        self.supportsIPv4 = nwPath.supportsIPv4
        self.supportsIPv6 = nwPath.supportsIPv6
        self.supportsDNS = nwPath.supportsDNS
        self.timestamp = Date()
        
        // 确定连接类型 - 优先选择最佳接口类型
        if nwPath.status == .satisfied {
            // 按优先级顺序检查接口类型：有线 > WiFi > 蜂窝 > 其他
            if nwPath.usesInterfaceType(.wiredEthernet) {
                self.connectionType = .wiredEthernet
            } else if nwPath.usesInterfaceType(.wifi) {
                self.connectionType = .wifi
            } else if nwPath.usesInterfaceType(.cellular) {
                self.connectionType = .cellular
            } else if nwPath.usesInterfaceType(.loopback) {
                self.connectionType = .loopback
            } else {
                self.connectionType = .other
            }
        } else {
            self.connectionType = .unavailable
        }
    }
    
    /// 手动创建 NetworkPath（主要用于测试）
    ///
    /// **用途**：单元测试和模拟场景
    ///
    /// - Parameters:
    ///   - status: 网络状态
    ///   - connectionType: 连接类型
    ///   - isExpensive: 是否昂贵
    ///   - isConstrained: 是否受限
    ///   - supportsIPv4: 是否支持 IPv4
    ///   - supportsIPv6: 是否支持 IPv6
    ///   - supportsDNS: 是否支持 DNS
    ///   - timestamp: 创建时间（默认为当前时间）
    public init(
        status: NWPath.Status,
        connectionType: ConnectionType,
        isExpensive: Bool = false,
        isConstrained: Bool = false,
        supportsIPv4: Bool = true,
        supportsIPv6: Bool = true,
        supportsDNS: Bool = true,
        timestamp: Date = Date()
    ) {
        self.status = status
        self.connectionType = connectionType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.supportsIPv4 = supportsIPv4
        self.supportsIPv6 = supportsIPv6
        self.supportsDNS = supportsDNS
        self.timestamp = timestamp
    }
}

// MARK: - 计算属性

public extension NetworkPath {
    /// 网络是否可用
    ///
    /// **判断依据**：status 为 satisfied 且连接类型不是 unavailable
    var isNetworkAvailable: Bool {
        return status == .satisfied && connectionType.isAvailable
    }
    
    /// 网络质量评估
    ///
    /// **评估逻辑**（按优先级）：
    /// 1. 网络不可用 → poor
    /// 2. 用户启用低数据模式 → fair（尊重用户意图）
    /// 3. 昂贵网络（蜂窝） → good（避免额外费用）
    /// 4. 其他情况 → excellent（WiFi/有线等）
    ///
    /// **设计考虑**：优先考虑用户体验和成本控制
    var quality: NetworkQuality {
        // 网络不可用是最高优先级
        guard status == .satisfied else {
            return .poor
        }
        
        // 用户明确开启低数据模式，应优先尊重用户意图
        if isConstrained {
            return .fair
        }
        
        // 昂贵网络次之，避免产生额外费用
        if isExpensive {
            return .good
        }
        
        // 其他情况视为最佳（免费且无限制）
        return .excellent
    }
    
    /// 是否建议进行大文件传输
    ///
    /// **判断条件**：网络质量为 excellent 且不是移动网络
    var isGoodForLargeTransfers: Bool {
        return quality == .excellent && !connectionType.isMobileNetwork
    }
    
    /// 是否建议启用高质量媒体
    ///
    /// **判断条件**：网络质量为 good 及以上
    var isGoodForHighQualityMedia: Bool {
        return quality.isHighQuality
    }
    
    /// 网络稳定性评分（0-100）
    ///
    /// **评分依据**：
    /// - 有线网络最稳定（100）
    /// - WiFi 次之（90）
    /// - 蜂窝网络受信号影响（70）
    /// - 其他类型未知（50）
    /// - 不可用网络（0）
    var stabilityScore: Int {
        guard isNetworkAvailable else { return 0 }
        
        switch connectionType {
        case .wiredEthernet:
            return 100
        case .wifi:
            return 90
        case .cellular:
            return 70
        case .loopback:
            return 100
        case .other:
            return 50
        case .unavailable:
            return 0
        }
    }
}

// MARK: - 描述和调试

public extension NetworkPath {
    /// 简短的状态描述
    var shortDescription: String {
        return "\(connectionType.displayName) - \(quality.displayName)"
    }
    
    /// 详细的状态描述
    var detailedDescription: String {
        var components: [String] = []
        
        components.append("连接类型: \(connectionType.displayName)")
        components.append("状态: \(status)")
        components.append("质量: \(quality.displayName)")
        
        if isExpensive {
            components.append("昂贵网络")
        }
        
        if isConstrained {
            components.append("低数据模式")
        }
        
        var protocols: [String] = []
        if supportsIPv4 { protocols.append("IPv4") }
        if supportsIPv6 { protocols.append("IPv6") }
        if supportsDNS { protocols.append("DNS") }
        
        if !protocols.isEmpty {
            components.append("协议支持: \(protocols.joined(separator: ", "))")
        }
        
        return components.joined(separator: " | ")
    }
}

// MARK: - Codable 支持

extension NetworkPath {
    /// 编码键
    private enum CodingKeys: String, CodingKey {
        case status
        case connectionType
        case isExpensive
        case isConstrained
        case supportsIPv4
        case supportsIPv6
        case supportsDNS
        case timestamp
    }
    
    /// 自定义编码实现
    ///
    /// **注意**：NWPath.Status 需要特殊处理，因为它不直接支持 Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 将 NWPath.Status 转换为字符串存储
        let statusString: String
        switch status {
        case .satisfied:
            statusString = "satisfied"
        case .unsatisfied:
            statusString = "unsatisfied"
        case .requiresConnection:
            statusString = "requiresConnection"
        @unknown default:
            statusString = "unknown"
        }
        
        try container.encode(statusString, forKey: .status)
        try container.encode(connectionType, forKey: .connectionType)
        try container.encode(isExpensive, forKey: .isExpensive)
        try container.encode(isConstrained, forKey: .isConstrained)
        try container.encode(supportsIPv4, forKey: .supportsIPv4)
        try container.encode(supportsIPv6, forKey: .supportsIPv6)
        try container.encode(supportsDNS, forKey: .supportsDNS)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    /// 自定义解码实现
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 从字符串恢复 NWPath.Status
        let statusString = try container.decode(String.self, forKey: .status)
        switch statusString {
        case "satisfied":
            self.status = .satisfied
        case "unsatisfied":
            self.status = .unsatisfied
        case "requiresConnection":
            self.status = .requiresConnection
        default:
            self.status = .unsatisfied
        }
        
        self.connectionType = try container.decode(ConnectionType.self, forKey: .connectionType)
        self.isExpensive = try container.decode(Bool.self, forKey: .isExpensive)
        self.isConstrained = try container.decode(Bool.self, forKey: .isConstrained)
        self.supportsIPv4 = try container.decode(Bool.self, forKey: .supportsIPv4)
        self.supportsIPv6 = try container.decode(Bool.self, forKey: .supportsIPv6)
        self.supportsDNS = try container.decode(Bool.self, forKey: .supportsDNS)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
}