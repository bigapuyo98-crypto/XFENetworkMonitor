import Foundation
import Network

/// 网络连接类型枚举
///
/// 定义了应用可能遇到的各种网络连接类型，基于 NWInterface.InterfaceType 进行封装
/// 提供更友好的 API 和扩展功能
///
/// **设计原则**：
/// - 使用 String 原始值便于序列化和调试
/// - 提供 CaseIterable 支持遍历所有类型
/// - 包含 unavailable 状态表示无网络连接
public enum ConnectionType: String, CaseIterable, Codable {
    /// WiFi 连接 - 通常速度快、成本低、稳定性好
    case wifi = "wifi"
    
    /// 蜂窝网络连接 - 可能有流量费用、速度受信号影响
    case cellular = "cellular"
    
    /// 有线以太网连接 - 通常速度最快、最稳定
    case wiredEthernet = "wiredEthernet"
    
    /// 环回接口 - 本地回环，主要用于测试
    case loopback = "loopback"
    
    /// 其他类型连接 - 未知或不常见的连接类型
    case other = "other"
    
    /// 网络不可用 - 无任何可用网络连接
    case unavailable = "unavailable"
}

// MARK: - NWInterface.InterfaceType 转换

public extension ConnectionType {
    /// 从 NWInterface.InterfaceType 创建 ConnectionType
    ///
    /// **转换逻辑**：
    /// - 直接映射常见类型（wifi、cellular、wiredEthernet、loopback）
    /// - 其他类型统一归类为 other
    ///
    /// - Parameter interfaceType: Network framework 的接口类型
    init(from interfaceType: NWInterface.InterfaceType) {
        switch interfaceType {
        case .wifi:
            self = .wifi
        case .cellular:
            self = .cellular
        case .wiredEthernet:
            self = .wiredEthernet
        case .loopback:
            self = .loopback
        case .other:
            self = .other
        @unknown default:
            // 未来新增的接口类型默认归类为 other
            self = .other
        }
    }
    
    /// 转换为 NWInterface.InterfaceType
    ///
    /// **注意**：unavailable 类型无法转换，返回 nil
    ///
    /// - Returns: 对应的 NWInterface.InterfaceType，unavailable 时返回 nil
    var nwInterfaceType: NWInterface.InterfaceType? {
        switch self {
        case .wifi:
            return .wifi
        case .cellular:
            return .cellular
        case .wiredEthernet:
            return .wiredEthernet
        case .loopback:
            return .loopback
        case .other:
            return .other
        case .unavailable:
            return nil
        }
    }
}

// MARK: - 描述和显示

public extension ConnectionType {
    /// 用户友好的显示名称
    ///
    /// **本地化考虑**：当前使用中文，后续可扩展为多语言支持
    var displayName: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "蜂窝网络"
        case .wiredEthernet:
            return "有线网络"
        case .loopback:
            return "本地回环"
        case .other:
            return "其他网络"
        case .unavailable:
            return "网络不可用"
        }
    }
    
    /// 详细描述信息
    var description: String {
        switch self {
        case .wifi:
            return "WiFi 无线网络连接"
        case .cellular:
            return "蜂窝移动网络连接"
        case .wiredEthernet:
            return "有线以太网连接"
        case .loopback:
            return "本地环回接口"
        case .other:
            return "其他类型网络连接"
        case .unavailable:
            return "当前无可用网络连接"
        }
    }
}

// MARK: - 网络特性判断

public extension ConnectionType {
    /// 是否为移动网络（可能产生流量费用）
    ///
    /// **用途**：帮助应用决定是否启用数据节省模式
    var isMobileNetwork: Bool {
        return self == .cellular
    }
    
    /// 是否为高速网络（通常速度较快且稳定）
    ///
    /// **判断依据**：WiFi 和有线网络通常速度更快且更稳定
    var isHighSpeedNetwork: Bool {
        return self == .wifi || self == .wiredEthernet
    }
    
    /// 是否为可用网络连接
    ///
    /// **用途**：快速判断是否可以进行网络请求
    var isAvailable: Bool {
        return self != .unavailable
    }
}