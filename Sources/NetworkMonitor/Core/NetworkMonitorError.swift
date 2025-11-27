import Foundation
import Network

/// 网络监测器错误类型
///
/// **设计理念**：
/// - 覆盖所有可能的错误场景，提供清晰的错误分类
/// - 遵循 Swift 错误处理最佳实践，实现 LocalizedError 和 CustomNSError
/// - 提供详细的中文错误描述和恢复建议，提升用户体验
/// - 支持错误链传递（underlying error），保留原始错误信息
///
/// **为什么需要自定义错误类型**：
/// - 类型安全：编译时检查，避免使用字符串或数字表示错误
/// - 信息丰富：包含错误原因、恢复建议、严重程度等多维度信息
/// - 易于处理：支持模式匹配，便于分类处理不同错误
/// - 可测试性：Mock 错误场景，编写完整的错误处理测试
///
/// **使用场景**：
/// - 监听器生命周期管理错误（启动/停止）
/// - 网络路径获取错误
/// - 配置和权限错误
/// - 超时和系统错误
public enum NetworkMonitorError: Error {
    
    // MARK: - 错误类型定义
    
    /// 监听器未启动
    ///
    /// **发生时机**：在调用需要监听器运行的方法时，如果监听器未启动则抛出
    /// **常见场景**：尝试获取当前网络路径，但监听器未启动
    ///
    /// **为什么会发生**：
    /// - 忘记调用 startMonitoring() 方法
    /// - 监听器已被停止但仍尝试访问网络信息
    ///
    /// **如何处理**：
    /// - 先调用 startMonitoring() 启动监听器
    /// - 检查 isMonitoring 属性确认监听状态
    case monitorNotStarted
    
    /// 网络路径不可用
    ///
    /// **发生时机**：当尝试获取网络路径信息但路径不可用时抛出
    /// **常见场景**：网络完全断开，无法获取任何网络信息
    ///
    /// **为什么会发生**：
    /// - 设备未连接任何网络（WiFi、蜂窝、有线）
    /// - 网络硬件故障或被禁用
    /// - 飞行模式开启
    ///
    /// **如何处理**：
    /// - 提示用户检查网络连接
    /// - 提供离线模式或缓存数据
    /// - 等待网络恢复后重试
    case pathUnavailable
    
    /// 无效的配置
    ///
    /// **发生时机**：监听器配置无效时抛出，包含具体的错误原因
    /// **常见场景**：指定了不支持的接口类型或无效的参数
    ///
    /// **为什么会发生**：
    /// - 传入了 nil 或无效的配置参数
    /// - 配置参数之间存在冲突
    ///
    /// **如何处理**：
    /// - 检查配置参数的有效性
    /// - 使用默认配置或推荐配置
    /// - 参考文档确认正确的配置方式
    ///
    /// - Parameter reason: 配置无效的具体原因
    case invalidConfiguration(reason: String)
    
    /// 系统错误
    ///
    /// **发生时机**：底层系统 API 返回错误时抛出，包含原始错误信息
    /// **常见场景**：系统资源不足、权限问题、系统 API 调用失败
    ///
    /// **为什么会发生**：
    /// - 系统资源（内存、文件描述符）不足
    /// - 系统 API 内部错误
    /// - 操作系统版本不兼容
    ///
    /// **如何处理**：
    /// - 记录详细的错误日志
    /// - 重启应用或设备
    /// - 联系技术支持
    ///
    /// - Parameter underlying: 底层系统错误
    case systemError(underlying: Error)
    
    /// 监听器已在运行
    ///
    /// **发生时机**：尝试启动已经在运行的监听器时抛出
    /// **常见场景**：重复调用 startMonitoring() 方法
    ///
    /// **为什么会发生**：
    /// - 多次调用启动方法
    /// - 未检查监听状态就启动
    ///
    /// **如何处理**：
    /// - 调用前检查 isMonitoring 属性
    /// - 这是一个警告性错误，不影响功能
    case alreadyMonitoring
    
    /// 监听器未在运行
    ///
    /// **发生时机**：尝试停止未在运行的监听器时抛出
    /// **常见场景**：重复调用 stopMonitoring() 方法
    ///
    /// **为什么会发生**：
    /// - 多次调用停止方法
    /// - 监听器从未启动就尝试停止
    ///
    /// **如何处理**：
    /// - 调用前检查 isMonitoring 属性
    /// - 这是一个警告性错误，不影响功能
    case notMonitoring
    
    /// 超时错误
    ///
    /// **发生时机**：等待网络状态变化超时时抛出
    /// **常见场景**：等待网络连接恢复超过指定时间
    ///
    /// **为什么会发生**：
    /// - 网络恢复时间过长
    /// - 超时时间设置过短
    /// - 网络持续不可用
    ///
    /// **如何处理**：
    /// - 增加超时时间
    /// - 提示用户检查网络
    /// - 提供取消操作选项
    ///
    /// - Parameter duration: 超时时长（秒）
    case timeout(duration: TimeInterval)
    
    /// 权限不足
    ///
    /// **发生时机**：缺少必要的网络访问权限时抛出
    /// **常见场景**：应用未获得网络访问权限
    ///
    /// **为什么会发生**：
    /// - 用户拒绝了网络访问权限
    /// - 系统限制了网络访问
    /// - 企业策略禁止网络访问
    ///
    /// **如何处理**：
    /// - 引导用户前往设置开启权限
    /// - 提供权限说明和必要性解释
    /// - 提供无网络模式的降级方案
    case insufficientPermissions
}

// MARK: - LocalizedError

/// LocalizedError 协议实现
///
/// **设计目的**：
/// - 提供用户友好的中文错误描述
/// - 提供详细的恢复建议，帮助用户解决问题
/// - 符合 iOS 错误处理规范
///
/// **好处**：
/// - 错误信息本地化，提升用户体验
/// - 统一的错误展示格式
/// - 便于在 UI 中直接显示错误信息
extension NetworkMonitorError: LocalizedError {

    /// 用户友好的错误描述
    ///
    /// **设计原则**：
    /// - 使用简洁明了的中文描述
    /// - 说明错误的具体原因
    /// - 避免技术术语，面向普通用户
    public var errorDescription: String? {
        switch self {
        case .monitorNotStarted:
            return "网络监听器未启动，请先调用 startMonitoring() 方法"

        case .pathUnavailable:
            return "无法获取网络路径信息，请检查网络连接"

        case .invalidConfiguration(let reason):
            return "监听器配置无效：\(reason)"

        case .systemError(let underlying):
            return "系统错误：\(underlying.localizedDescription)"

        case .alreadyMonitoring:
            return "监听器已在运行，无需重复启动"

        case .notMonitoring:
            return "监听器未在运行，无法执行停止操作"

        case .timeout(let duration):
            return "等待网络状态变化超时（\(duration) 秒）"

        case .insufficientPermissions:
            return "缺少网络访问权限，请检查应用权限设置"
        }
    }

    /// 错误恢复建议
    ///
    /// **设计原则**：
    /// - 提供具体的操作步骤
    /// - 帮助用户快速解决问题
    /// - 包含替代方案
    public var recoverySuggestion: String? {
        switch self {
        case .monitorNotStarted:
            return "调用 NetworkMonitor.shared.startMonitoring() 启动监听"

        case .pathUnavailable:
            return "检查设备网络连接，确保网络可用"

        case .invalidConfiguration:
            return "检查监听器初始化参数，确保配置正确"

        case .systemError:
            return "重启应用或设备，如问题持续请联系技术支持"

        case .alreadyMonitoring:
            return "无需操作，监听器已正常运行"

        case .notMonitoring:
            return "先启动监听器，再执行相关操作"

        case .timeout:
            return "增加超时时间或检查网络连接稳定性"

        case .insufficientPermissions:
            return "前往设置 > 隐私与安全性 > 网络，允许应用访问网络"
        }
    }
}

// MARK: - CustomNSError

/// CustomNSError 协议实现
///
/// **设计目的**：
/// - 提供标准的 NSError 兼容性
/// - 支持 Objective-C 互操作
/// - 提供错误代码和用户信息字典
///
/// **好处**：
/// - 与 Cocoa 框架无缝集成
/// - 支持错误日志和分析工具
/// - 便于错误追踪和调试
extension NetworkMonitorError: CustomNSError {

    /// 错误域
    ///
    /// **命名规范**：使用反向域名格式，避免冲突
    public static var errorDomain: String {
        return "com.networkmonitor.error"
    }

    /// 错误代码
    ///
    /// **编码规则**：
    /// - 1001-1099: 监听器生命周期错误
    /// - 1100-1199: 网络路径错误
    /// - 1200-1299: 配置和权限错误
    /// - 1300-1399: 超时和系统错误
    public var errorCode: Int {
        switch self {
        case .monitorNotStarted: return 1001
        case .alreadyMonitoring: return 1002
        case .notMonitoring: return 1003
        case .pathUnavailable: return 1101
        case .invalidConfiguration: return 1201
        case .insufficientPermissions: return 1202
        case .timeout: return 1301
        case .systemError: return 1302
        }
    }

    /// 用户信息字典
    ///
    /// **包含内容**：
    /// - NSLocalizedDescriptionKey: 错误描述
    /// - NSLocalizedRecoverySuggestionErrorKey: 恢复建议
    /// - 错误特定的附加信息
    ///
    /// **好处**：
    /// - 提供丰富的错误上下文
    /// - 便于错误分析和调试
    /// - 支持错误链传递
    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: errorDescription ?? "未知错误",
            NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion ?? ""
        ]

        // 添加错误特定的附加信息
        switch self {
        case .invalidConfiguration(let reason):
            userInfo["reason"] = reason

        case .systemError(let underlying):
            userInfo[NSUnderlyingErrorKey] = underlying

        case .timeout(let duration):
            userInfo["timeout"] = duration

        default:
            break
        }

        return userInfo
    }
}

// MARK: - Error Handling Utilities

/// 错误处理工具扩展
///
/// **设计目的**：
/// - 提供错误分类和判断方法
/// - 帮助应用做出正确的错误处理决策
/// - 支持自动恢复和用户干预判断
///
/// **好处**：
/// - 简化错误处理逻辑
/// - 统一的错误分类标准
/// - 提高代码可读性和可维护性
public extension NetworkMonitorError {

    /// 是否为可恢复错误
    ///
    /// **判断标准**：
    /// - 可恢复：错误可以通过重试或简单操作解决
    /// - 不可恢复：需要修改配置或系统设置才能解决
    ///
    /// **使用场景**：
    /// - 决定是否自动重试操作
    /// - 选择错误处理策略
    ///
    /// **为什么这样分类**：
    /// - monitorNotStarted: 可恢复 - 只需启动监听器
    /// - pathUnavailable: 可恢复 - 等待网络恢复
    /// - alreadyMonitoring/notMonitoring: 可恢复 - 状态问题，不影响功能
    /// - timeout: 可恢复 - 可以重试或增加超时时间
    /// - invalidConfiguration: 不可恢复 - 需要修改代码
    /// - systemError: 不可恢复 - 系统级问题
    /// - insufficientPermissions: 不可恢复 - 需要用户授权
    var isRecoverable: Bool {
        switch self {
        case .monitorNotStarted, .pathUnavailable, .alreadyMonitoring, .notMonitoring, .timeout:
            return true
        case .invalidConfiguration, .systemError, .insufficientPermissions:
            return false
        }
    }

    /// 是否需要用户干预
    ///
    /// **判断标准**：
    /// - 需要用户干预：必须由用户执行某些操作才能解决
    /// - 不需要用户干预：应用可以自动处理或忽略
    ///
    /// **使用场景**：
    /// - 决定是否显示用户提示
    /// - 选择错误展示方式
    ///
    /// **为什么这样分类**：
    /// - insufficientPermissions: 需要用户授权
    /// - pathUnavailable: 需要用户检查网络连接
    /// - 其他错误：应用可以自动处理
    var requiresUserIntervention: Bool {
        switch self {
        case .insufficientPermissions, .pathUnavailable:
            return true
        default:
            return false
        }
    }

    /// 错误严重程度
    ///
    /// **分级标准**：
    /// - low: 不影响核心功能，可以忽略或自动恢复
    /// - medium: 影响部分功能，需要提示用户
    /// - high: 影响核心功能，必须解决
    ///
    /// **使用场景**：
    /// - 错误日志级别选择
    /// - 错误上报优先级
    /// - UI 提示方式选择
    ///
    /// **为什么这样分级**：
    /// - low: 状态错误（alreadyMonitoring/notMonitoring）- 不影响功能
    /// - medium: 临时性错误（pathUnavailable/timeout）- 可能恢复
    /// - high: 配置和权限错误 - 必须解决才能使用
    var severity: ErrorSeverity {
        switch self {
        case .monitorNotStarted, .alreadyMonitoring, .notMonitoring:
            return .low
        case .pathUnavailable, .timeout:
            return .medium
        case .invalidConfiguration, .systemError, .insufficientPermissions:
            return .high
        }
    }
}

/// 错误严重程度枚举
///
/// **设计理念**：
/// - 使用 Int 作为 RawValue，便于比较和排序
/// - 遵循 CaseIterable，支持遍历所有级别
/// - 提供清晰的语义化命名
///
/// **使用场景**：
/// - 错误日志分级
/// - 错误上报优先级
/// - 错误处理策略选择
public enum ErrorSeverity: Int, CaseIterable {
    /// 低 - 不影响核心功能
    ///
    /// **特征**：
    /// - 可以忽略或自动恢复
    /// - 不需要用户干预
    /// - 不影响应用正常使用
    ///
    /// **示例**：
    /// - 重复启动/停止监听器
    /// - 状态检查失败
    case low = 1

    /// 中 - 影响部分功能
    ///
    /// **特征**：
    /// - 需要提示用户
    /// - 可能自动恢复
    /// - 影响部分功能但不致命
    ///
    /// **示例**：
    /// - 网络暂时不可用
    /// - 操作超时
    case medium = 2

    /// 高 - 影响核心功能
    ///
    /// **特征**：
    /// - 必须解决才能使用
    /// - 需要用户或开发者干预
    /// - 影响核心功能
    ///
    /// **示例**：
    /// - 配置错误
    /// - 权限不足
    /// - 系统错误
    case high = 3
}

// MARK: - Result Type Extensions

/// Result 类型扩展
///
/// **设计目的**：
/// - 提供便捷的错误结果创建方法
/// - 简化 Result 类型的使用
/// - 提高代码可读性
///
/// **好处**：
/// - 减少重复代码
/// - 统一的错误返回方式
/// - 类型安全的错误处理
public extension Result where Failure == NetworkMonitorError {

    /// 创建监听器未启动的失败结果
    ///
    /// **使用场景**：需要返回监听器未启动错误时
    ///
    /// **示例**：
    /// ```swift
    /// func getCurrentPath() -> Result<NetworkPath, NetworkMonitorError> {
    ///     guard isMonitoring else {
    ///         return .monitorNotStarted
    ///     }
    ///     // ...
    /// }
    /// ```
    static var monitorNotStarted: Result<Success, NetworkMonitorError> {
        return .failure(.monitorNotStarted)
    }

    /// 创建路径不可用的失败结果
    ///
    /// **使用场景**：需要返回路径不可用错误时
    ///
    /// **示例**：
    /// ```swift
    /// func getCurrentPath() -> Result<NetworkPath, NetworkMonitorError> {
    ///     guard let path = currentPath else {
    ///         return .pathUnavailable
    ///     }
    ///     return .success(path)
    /// }
    /// ```
    static var pathUnavailable: Result<Success, NetworkMonitorError> {
        return .failure(.pathUnavailable)
    }
}

