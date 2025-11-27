import Foundation

// MARK: - Delegate Protocols

/// 网络监测代理协议
///
/// **设计理念**：
/// - 遵循 iOS 标准代理模式，第一个参数总是发送者
/// - 必须实现的方法：网络路径变化通知
/// - 可选实现的方法：通过协议扩展提供默认空实现
///
/// **适用场景**：
/// - 需要处理多种网络事件的复杂业务逻辑
/// - ViewController 中监听网络状态变化
/// - 需要细粒度控制的网络状态管理
///
/// **为什么使用代理模式**：
/// - 类型安全：编译时检查方法签名
/// - 解耦合：通过协议而非具体类型通信
/// - 易于测试：可以创建 Mock 代理用于测试
///
/// **使用示例**：
/// ```swift
/// class MyViewController: UIViewController, NetworkMonitorDelegate {
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         NetworkMonitor.shared.delegate = self
///     }
///
///     func networkMonitor(_ monitor: NetworkMonitoring, didUpdatePath path: NetworkPath) {
///         print("网络状态: \(path.connectionType.displayName)")
///         updateUI(with: path)
///     }
/// }
/// ```
public protocol NetworkMonitorDelegate: AnyObject {
    
    // MARK: - Required Method
    
    /// 网络路径发生变化（必须实现）
    ///
    /// **调用时机**：网络状态发生任何变化时
    /// **执行线程**：主线程（便于 UI 更新）
    ///
    /// **为什么必须实现**：
    /// - 这是最基础的网络变化通知
    /// - 代理必须知道网络状态发生了变化
    /// - 其他可选方法都是基于此方法的细化
    ///
    /// - Parameters:
    ///   - monitor: 发送通知的监听器
    ///   - path: 新的网络路径信息
    func networkMonitor(_ monitor: NetworkMonitoring, didUpdatePath path: NetworkPath)
    
    // MARK: - Optional Methods
    
    /// 网络监听遇到错误（可选）
    ///
    /// **调用时机**：监听过程中发生错误时
    /// **常见错误**：系统资源不足、权限问题
    ///
    /// - Parameters:
    ///   - monitor: 发送通知的监听器
    ///   - error: 遇到的错误
    func networkMonitor(_ monitor: NetworkMonitoring, didEncounterError error: Error)
    
    /// 网络监听开始（可选）
    ///
    /// **调用时机**：调用 startMonitoring() 成功后
    /// **使用场景**：显示监听状态指示器
    ///
    /// - Parameter monitor: 发送通知的监听器
    func networkMonitorDidStartMonitoring(_ monitor: NetworkMonitoring)
    
    /// 网络监听停止（可选）
    ///
    /// **调用时机**：调用 stopMonitoring() 后
    /// **使用场景**：清理资源、隐藏状态指示器
    ///
    /// - Parameter monitor: 发送通知的监听器
    func networkMonitorDidStopMonitoring(_ monitor: NetworkMonitoring)
}

// MARK: - Delegate Protocol Extensions (Optional Methods)

/// 协议扩展 - 为可选方法提供默认空实现
///
/// **设计优势**：
/// - 代理只需实现关心的方法
/// - 避免强制实现所有方法
/// - 保持代码简洁
public extension NetworkMonitorDelegate {
    
    func networkMonitor(_ monitor: NetworkMonitoring, didEncounterError error: Error) {
        // 默认空实现，错误处理为可选
    }
    
    func networkMonitorDidStartMonitoring(_ monitor: NetworkMonitoring) {
        // 默认空实现，开始监听通知为可选
    }
    
    func networkMonitorDidStopMonitoring(_ monitor: NetworkMonitoring) {
        // 默认空实现，停止监听通知为可选
    }
}

// MARK: - Observer Protocol

/// 网络路径观察者协议
///
/// **设计理念**：
/// - 最小化接口，只有一个方法
/// - 简化的观察者模式，仅关注网络路径变化
/// - 适用于不需要细粒度控制的简单场景
///
/// **适用场景**：
/// - 只需要监听网络变化的简单场景
/// - 不关心监听器生命周期事件
/// - 快速集成网络监听功能
///
/// **为什么需要这个协议**：
/// - NetworkMonitorDelegate 功能太多，简单场景用不到
/// - 减少实现负担，提高开发效率
/// - 符合单一职责原则
///
/// **使用示例**：
/// ```swift
/// class ImageDownloader: NetworkPathObserver {
///     func networkPathDidChange(_ path: NetworkPath) {
///         if path.isNetworkAvailable {
///             resumeDownloads()
///         } else {
///             pauseDownloads()
///         }
///     }
/// }
/// ```
public protocol NetworkPathObserver: AnyObject {
    
    /// 网络路径发生变化
    ///
    /// **调用时机**：网络状态发生任何变化时
    /// **执行线程**：主线程
    ///
    /// - Parameter path: 新的网络路径信息
    func networkPathDidChange(_ path: NetworkPath)
}

// MARK: - Type Aliases for Closures

/// 网络路径更新回调
///
/// **用途**：闭包形式的网络路径变化通知
/// **执行线程**：主线程
///
/// **使用场景**：
/// - 简单的网络状态监听
/// - 不需要代理模式的场景
/// - 快速原型开发
///
/// **使用示例**：
/// ```swift
/// NetworkMonitor.shared.pathUpdateHandler = { path in
///     print("网络质量: \(path.quality.displayName)")
/// }
/// ```
///
/// - Parameter path: 新的网络路径信息
public typealias PathUpdateHandler = (NetworkPath) -> Void

/// 网络错误处理回调
///
/// **用途**：闭包形式的错误处理
/// **执行线程**：主线程
///
/// **常见错误**：
/// - 系统资源不足
/// - 权限问题
/// - 监听器启动失败
///
/// **使用示例**：
/// ```swift
/// NetworkMonitor.shared.errorHandler = { error in
///     print("网络监听错误: \(error.localizedDescription)")
/// }
/// ```
///
/// - Parameter error: 遇到的错误
public typealias NetworkErrorHandler = (Error) -> Void

/// 网络状态变化回调
///
/// **用途**：简化的布尔状态通知
/// **执行线程**：主线程
///
/// **使用场景**：
/// - 只关心网络是否可用
/// - 简单的在线/离线状态切换
/// - UI 状态指示器
///
/// **使用示例**：
/// ```swift
/// monitor.availabilityHandler = { isAvailable in
///     statusLabel.text = isAvailable ? "在线" : "离线"
/// }
/// ```
///
/// - Parameter isAvailable: 网络是否可用
public typealias NetworkAvailabilityHandler = (Bool) -> Void

/// 网络质量变化回调
///
/// **用途**：网络质量等级变化通知
/// **执行线程**：主线程
///
/// **使用场景**：
/// - 根据网络质量调整媒体质量
/// - 动态调整数据传输策略
/// - 显示网络质量指示器
///
/// **使用示例**：
/// ```swift
/// monitor.qualityHandler = { quality in
///     switch quality {
///     case .excellent: enableHDVideo()
///     case .good: enableSDVideo()
///     default: enableLowQualityMode()
///     }
/// }
/// ```
///
/// - Parameter quality: 新的网络质量等级
public typealias NetworkQualityHandler = (NetworkQuality) -> Void

/// 连接类型变化回调
///
/// **用途**：网络连接类型变化通知
/// **执行线程**：主线程
///
/// **使用场景**：
/// - WiFi/蜂窝网络切换检测
/// - 根据连接类型调整行为
/// - 流量统计和提醒
///
/// **使用示例**：
/// ```swift
/// monitor.connectionTypeHandler = { type in
///     if type == .cellular {
///         showDataUsageWarning()
///     }
/// }
/// ```
///
/// - Parameter connectionType: 新的连接类型
public typealias ConnectionTypeHandler = (ConnectionType) -> Void

// MARK: - Notification Names

/// 网络相关通知名称
///
/// **设计理念**：
/// - 使用反向域名命名规范，避免冲突
/// - 语义化命名，清晰表达通知含义
/// - 统一前缀 "NetworkMonitor"
///
/// **为什么使用 NotificationCenter**：
/// - 松耦合：发送者和接收者无需直接引用
/// - 一对多：一个通知可以有多个观察者
/// - 跨模块：适合模块间通信
///
/// **使用场景**：
/// - 跨模块的网络状态同步
/// - 多个组件同时监听网络变化
/// - 不方便使用代理或闭包的场景
public extension Notification.Name {

    /// 网络路径发生变化
    ///
    /// **发送时机**：网络状态发生任何变化时
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.networkPath`: NetworkPath - 新的网络路径信息
    /// - `NetworkNotificationKeys.previousPath`: NetworkPath? - 之前的网络路径信息（可选）
    ///
    /// **使用示例**：
    /// ```swift
    /// NotificationCenter.default.addObserver(
    ///     forName: .networkPathDidChange,
    ///     object: nil,
    ///     queue: .main
    /// ) { notification in
    ///     if let path = notification.userInfo?[NetworkNotificationKeys.networkPath] as? NetworkPath {
    ///         print("网络变化: \(path.connectionType)")
    ///     }
    /// }
    /// ```
    static let networkPathDidChange = Notification.Name("com.networkmonitor.pathDidChange")

    /// 网络监听开始
    ///
    /// **发送时机**：调用 startMonitoring() 成功后
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.monitor`: NetworkMonitoring - 监听器实例
    ///
    /// **使用场景**：
    /// - 显示网络监听状态指示器
    /// - 记录监听开始时间
    static let networkMonitorDidStart = Notification.Name("com.networkmonitor.didStart")

    /// 网络监听停止
    ///
    /// **发送时机**：调用 stopMonitoring() 后
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.monitor`: NetworkMonitoring - 监听器实例
    ///
    /// **使用场景**：
    /// - 隐藏网络监听状态指示器
    /// - 清理相关资源
    static let networkMonitorDidStop = Notification.Name("com.networkmonitor.didStop")

    /// 网络变为可用
    ///
    /// **发送时机**：网络从不可用变为可用时
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.networkPath`: NetworkPath - 当前网络路径信息
    ///
    /// **使用场景**：
    /// - 恢复网络请求
    /// - 同步离线数据
    /// - 显示在线模式 UI
    ///
    /// **使用示例**：
    /// ```swift
    /// NotificationCenter.default.addObserver(
    ///     forName: .networkDidBecomeAvailable,
    ///     object: nil,
    ///     queue: .main
    /// ) { _ in
    ///     resumeNetworkRequests()
    /// }
    /// ```
    static let networkDidBecomeAvailable = Notification.Name("com.networkmonitor.didBecomeAvailable")

    /// 网络变为不可用
    ///
    /// **发送时机**：网络从可用变为不可用时
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.previousPath`: NetworkPath? - 之前的网络路径信息（可选）
    ///
    /// **使用场景**：
    /// - 暂停网络请求
    /// - 保存当前状态
    /// - 显示离线模式 UI
    ///
    /// **使用示例**：
    /// ```swift
    /// NotificationCenter.default.addObserver(
    ///     forName: .networkDidBecomeUnavailable,
    ///     object: nil,
    ///     queue: .main
    /// ) { _ in
    ///     pauseNetworkRequests()
    ///     showOfflineMessage()
    /// }
    /// ```
    static let networkDidBecomeUnavailable = Notification.Name("com.networkmonitor.didBecomeUnavailable")

    /// 网络质量发生变化
    ///
    /// **发送时机**：网络质量等级发生变化时
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.networkQuality`: NetworkQuality - 新的网络质量
    /// - `NetworkNotificationKeys.previousQuality`: NetworkQuality? - 之前的网络质量（可选）
    ///
    /// **使用场景**：
    /// - 动态调整媒体质量
    /// - 显示网络质量指示器
    /// - 优化数据传输策略
    static let networkQualityDidChange = Notification.Name("com.networkmonitor.qualityDidChange")

    /// 连接类型发生变化
    ///
    /// **发送时机**：网络连接类型发生变化时（如 WiFi 切换到蜂窝）
    ///
    /// **UserInfo 包含**：
    /// - `NetworkNotificationKeys.connectionType`: ConnectionType - 新的连接类型
    /// - `NetworkNotificationKeys.previousType`: ConnectionType? - 之前的连接类型（可选）
    ///
    /// **使用场景**：
    /// - WiFi/蜂窝网络切换检测
    /// - 流量统计和提醒
    /// - 根据连接类型调整行为
    static let connectionTypeDidChange = Notification.Name("com.networkmonitor.connectionTypeDidChange")
}

// MARK: - UserInfo Keys

/// 通知 UserInfo 键名
///
/// **设计理念**：
/// - 使用结构体命名空间组织常量
/// - 语义化命名，清晰表达键的含义
/// - 类型安全，避免字符串拼写错误
///
/// **为什么使用结构体而非枚举**：
/// - 结构体可以有静态常量
/// - 不需要实例化
/// - 更符合常量组织的语义
///
/// **使用示例**：
/// ```swift
/// let userInfo: [String: Any] = [
///     NetworkNotificationKeys.networkPath: currentPath,
///     NetworkNotificationKeys.previousPath: previousPath
/// ]
/// NotificationCenter.default.post(
///     name: .networkPathDidChange,
///     object: self,
///     userInfo: userInfo
/// )
/// ```
public struct NetworkNotificationKeys {

    /// 网络路径键
    ///
    /// **类型**：NetworkPath
    /// **用途**：当前的网络路径信息
    public static let networkPath = "networkPath"

    /// 之前的网络路径键
    ///
    /// **类型**：NetworkPath?
    /// **用途**：之前的网络路径信息（可选）
    public static let previousPath = "previousPath"

    /// 监听器键
    ///
    /// **类型**：NetworkMonitoring
    /// **用途**：发送通知的监听器实例
    public static let monitor = "monitor"

    /// 网络质量键
    ///
    /// **类型**：NetworkQuality
    /// **用途**：当前的网络质量等级
    public static let networkQuality = "networkQuality"

    /// 之前的网络质量键
    ///
    /// **类型**：NetworkQuality?
    /// **用途**：之前的网络质量等级（可选）
    public static let previousQuality = "previousQuality"

    /// 连接类型键
    ///
    /// **类型**：ConnectionType
    /// **用途**：当前的连接类型
    public static let connectionType = "connectionType"

    /// 之前的连接类型键
    ///
    /// **类型**：ConnectionType?
    /// **用途**：之前的连接类型（可选）
    public static let previousType = "previousType"

    /// 错误键
    ///
    /// **类型**：Error
    /// **用途**：发生的错误信息
    public static let error = "error"

    // 私有初始化方法，防止实例化
    private init() {}
}

