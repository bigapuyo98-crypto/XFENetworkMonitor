import Combine
import Foundation
import Network

/// 网络监测器 - 核心网络状态监听类
///
/// 提供实时的网络状态监测功能，基于 NWPathMonitor 封装
/// 采用单例模式确保全局唯一的网络监听实例
///
/// **设计原则**：
/// - 单例模式：全局唯一实例，避免多个监听器冲突
/// - 线程安全：使用专用队列处理网络回调，主线程分发通知
/// - 内存安全：使用 weak 引用避免循环引用
/// - 简单易用：提供闭包回调机制，便于集成
///
/// **使用场景**：
/// - 监测网络连接状态变化
/// - 根据网络质量调整应用行为
/// - 实现网络状态相关的 UI 更新
///
/// **线程模型**：
/// - 网络回调在专用后台队列执行
/// - 用户回调切换到主线程执行
/// - 确保 UI 更新的线程安全
public class NetworkMonitor: NetworkMonitoring {

    // MARK: - 单例

    /// 共享实例
    ///
    /// **设计考虑**：
    /// - 网络监听是全局性的系统资源
    /// - 避免多个监听器同时运行造成资源浪费
    /// - 提供统一的网络状态访问点
    public static let shared = NetworkMonitor()

    // MARK: - 私有属性

    /// 系统网络路径监听器
    ///
    /// **职责**：实际执行网络状态监听的系统组件
    private let pathMonitor: NWPathMonitor

    /// 网络监听专用队列
    ///
    /// **设计目的**：
    /// - 避免阻塞主线程
    /// - 提供稳定的回调执行环境
    /// - 使用 utility QoS 平衡性能和电量消耗
    private let monitorQueue: DispatchQueue

    /// 当前网络路径（线程安全访问）
    ///
    /// **访问控制**：
    /// - 私有 setter 确保只能通过监听器更新
    /// - 公开 getter 提供只读访问
    /// - 使用队列同步确保线程安全
    private var _currentPath: NetworkPath?

    /// 监听状态标记
    ///
    /// **用途**：跟踪监听器的运行状态，避免重复启动
    private var _isMonitoring: Bool = false

    // MARK: - 公开属性

    /// 当前网络路径（只读）
    ///
    /// **线程安全**：通过队列同步访问确保数据一致性
    /// **返回值**：当前的网络路径信息，未开始监听时为 nil
    public var currentPath: NetworkPath? {
        return monitorQueue.sync { _currentPath }
    }

    /// 监听状态（只读）
    ///
    /// **用途**：检查监听器是否正在运行
    public var isMonitoring: Bool {
        return monitorQueue.sync { _isMonitoring }
    }

    // MARK: - 回调属性

    /// 网络路径更新回调
    ///
    /// **执行线程**：主线程（便于 UI 更新）
    /// **调用时机**：网络状态发生变化时
    /// **参数**：新的网络路径信息
    ///
    /// **使用示例**：
    /// ```swift
    /// NetworkMonitor.shared.pathUpdateHandler = { path in
    ///     print("网络状态: \(path.connectionType.displayName)")
    ///     updateUI(with: path)
    /// }
    /// ```
    public var pathUpdateHandler: ((NetworkPath) -> Void)?

    /// 错误处理回调
    ///
    /// **执行线程**：主线程
    /// **调用时机**：监听过程中发生错误时
    /// **参数**：错误信息
    ///
    /// **常见错误**：
    /// - 系统资源不足
    /// - 权限问题
    /// - 监听器启动失败
    public var errorHandler: ((Error) -> Void)?

    // MARK: - Combine 支持

    /// Combine 发布者 - 网络路径变化流
    ///
    /// **设计模式**：响应式编程（Reactive Programming）
    ///
    /// **为什么使用 PassthroughSubject**：
    /// - 支持多个订阅者同时监听
    /// - 不保存历史值，只发送新的变化
    /// - 符合 Combine 的发布-订阅模式
    ///
    /// **为什么使用 Never 作为 Failure 类型**：
    /// - 网络路径变化不会产生错误（错误通过 errorHandler 处理）
    /// - 简化订阅代码，不需要处理错误情况
    /// - 符合 Combine 最佳实践
    ///
    /// **线程安全**：
    /// - 在主线程发送值，确保 UI 更新安全
    /// - 订阅者在主线程接收值
    ///
    /// **使用场景**：
    /// - SwiftUI 视图自动更新
    /// - Combine 管道处理网络状态
    /// - 响应式架构集成
    ///
    /// **使用示例**：
    /// ```swift
    /// NetworkMonitor.shared.pathPublisher
    ///     .sink { path in
    ///         print("网络变化: \(path.connectionType)")
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// **可用性**：iOS 13.0+, macOS 10.15+
    ///
    /// **Why**: 使用具体类型而非 Any，提供类型安全和编译时检查
    /// **好处**:
    /// - 编译器可以推断类型，无需手动转换
    /// - 支持代码补全和类型检查
    /// - 避免运行时类型转换错误
    @available(iOS 13.0, macOS 10.15, *)
    public let pathPublisher = PassthroughSubject<NetworkPath, Never>()

    // MARK: - 代理和观察者

    /// 网络监听代理
    ///
    /// **设计模式**：代理模式（Delegate Pattern）
    ///
    /// **为什么使用 weak**：
    /// - 避免循环引用（代理通常持有监听器）
    /// - 代理对象被释放时自动置为 nil
    /// - 符合 iOS 标准代理模式规范
    ///
    /// **使用场景**：
    /// - ViewController 需要响应网络变化
    /// - 需要实现多个回调方法的场景
    /// - 面向对象的架构设计
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
    ///         updateUI(with: path)
    ///     }
    /// }
    /// ```
    public weak var delegate: NetworkMonitorDelegate?

    /// 观察者集合
    ///
    /// **设计模式**：观察者模式（Observer Pattern）
    ///
    /// **为什么使用 NSHashTable.weakObjects()**：
    /// - 自动管理 weak 引用，避免循环引用
    /// - 观察者被释放时自动从集合中移除
    /// - 线程安全（使用锁保护）
    /// - 支持多个观察者同时监听
    ///
    /// **好处**：
    /// - 无需手动管理观察者生命周期
    /// - 避免内存泄漏
    /// - 支持一对多通知
    ///
    /// **使用场景**：
    /// - 多个组件需要监听网络变化
    /// - 松耦合的架构设计
    /// - 跨模块通信
    private let observers = NSHashTable<AnyObject>.weakObjects()

    /// 观察者访问锁
    ///
    /// **为什么需要锁**：
    /// - NSHashTable 不是线程安全的
    /// - 多线程同时添加/移除观察者会导致崩溃
    /// - 确保观察者集合的一致性
    private let observersLock = NSLock()

    /// 前一个网络路径（用于变化检测）
    ///
    /// **用途**：
    /// - 检测网络质量变化
    /// - 检测连接类型变化
    /// - 发送变化通知时提供前后对比
    private var previousPath: NetworkPath?

    // MARK: - 初始化

    /// 内部初始化方法
    ///
    /// **初始化内容**：
    /// - 创建 NWPathMonitor 实例（支持指定接口类型）
    /// - 设置专用监听队列
    /// - 配置路径更新处理逻辑
    ///
    /// **队列配置**：
    /// - 使用 utility QoS 平衡性能和电量
    /// - 串行队列确保回调顺序执行
    ///
    /// **为什么使用内部初始化方法**：
    /// - 支持创建通用监听器（监听所有接口）
    /// - 支持创建特定接口类型的监听器（WiFi、蜂窝等）
    /// - 保持单例模式的同时支持依赖注入
    ///
    /// - Parameter requiredInterfaceType: 要监听的接口类型，nil 表示监听所有接口
    internal init(requiredInterfaceType: NWInterface.InterfaceType? = nil) {
        // 根据参数创建对应的 NWPathMonitor
        if let interfaceType = requiredInterfaceType {
            self.pathMonitor = NWPathMonitor(requiredInterfaceType: interfaceType)
        } else {
            self.pathMonitor = NWPathMonitor()
        }

        self.monitorQueue = DispatchQueue(
            label: "com.networkmonitor.queue",
            qos: .utility
        )

        setupPathUpdateHandler()
    }

    // MARK: - 核心方法

    /// 开始网络监听
    ///
    /// **功能**：启动网络状态监听，开始接收网络变化通知
    /// **线程安全**：可以在任意线程调用
    /// **重复调用**：如果已在监听，重复调用无效果
    ///
    /// **执行流程**：
    /// 1. 检查当前监听状态
    /// 2. 启动 NWPathMonitor
    /// 3. 更新监听状态标记
    /// 4. 立即获取当前网络状态
    ///
    /// **使用示例**：
    /// ```swift
    /// let monitor = NetworkMonitor.shared
    /// monitor.pathUpdateHandler = { path in
    ///     print("网络变化: \(path.shortDescription)")
    /// }
    /// monitor.startMonitoring()
    /// ```
    public func startMonitoring() {
        monitorQueue.async { [weak self] in
            guard let self = self else { return }

            // 避免重复启动
            guard !self._isMonitoring else {
                print("⚠️ NetworkMonitor: 监听器已在运行")
                return
            }

            // 启动系统监听器
            self.pathMonitor.start(queue: self.monitorQueue)
            self._isMonitoring = true

            print("✅ NetworkMonitor: 开始监听网络状态")

            // 通知监听已启动
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.networkMonitorDidStartMonitoring(self)
                NotificationCenter.default.post(
                    name: .networkMonitorDidStart,
                    object: self,
                    userInfo: [NetworkNotificationKeys.monitor: self]
                )
            }
        }
    }

    /// 停止网络监听
    ///
    /// **功能**：停止网络状态监听，释放系统资源
    /// **线程安全**：可以在任意线程调用
    /// **重复调用**：如果未在监听，重复调用无效果
    ///
    /// **执行流程**：
    /// 1. 检查当前监听状态
    /// 2. 停止 NWPathMonitor
    /// 3. 更新监听状态标记
    /// 4. 清理当前路径信息
    ///
    /// **使用场景**：
    /// - 应用进入后台时节省资源
    /// - 页面销毁时清理监听器
    /// - 临时暂停网络监听
    public func stopMonitoring() {
        monitorQueue.async { [weak self] in
            guard let self = self else { return }

            // 检查是否正在监听
            guard self._isMonitoring else {
                print("⚠️ NetworkMonitor: 监听器未运行")
                return
            }

            // 停止系统监听器
            self.pathMonitor.cancel()
            self._isMonitoring = false

            print("🛑 NetworkMonitor: 停止监听网络状态")

            // 通知监听已停止
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.networkMonitorDidStopMonitoring(self)
                NotificationCenter.default.post(
                    name: .networkMonitorDidStop,
                    object: self,
                    userInfo: [NetworkNotificationKeys.monitor: self]
                )
            }
        }
    }

    // MARK: - 私有方法

    /// 设置路径更新处理逻辑
    ///
    /// **职责**：配置 NWPathMonitor 的回调处理
    /// **线程处理**：后台队列接收 → 主线程分发
    ///
    /// **处理流程**：
    /// 1. 接收系统网络路径更新
    /// 2. 转换为 NetworkPath 对象
    /// 3. 更新内部状态
    /// 4. 切换到主线程执行用户回调
    private func setupPathUpdateHandler() {
        pathMonitor.pathUpdateHandler = { [weak self] nwPath in
            self?.handlePathUpdate(nwPath)
        }
    }

    /// 处理网络路径更新
    ///
    /// **参数**：系统提供的网络路径信息
    /// **执行环境**：监听队列（后台线程）
    ///
    /// **处理逻辑**：
    /// 1. 转换系统路径为自定义格式
    /// 2. 检测状态变化
    /// 3. 更新内部状态
    /// 4. 分发变化通知
    ///
    /// - Parameter nwPath: 系统网络路径对象
    private func handlePathUpdate(_ nwPath: NWPath) {
        // 转换为自定义网络路径对象
        let newPath = NetworkPath(nwPath: nwPath)

        // 检查是否有实际变化（避免重复通知）
        let oldPath = _currentPath
        let hasChanged = oldPath != newPath

        // 更新内部状态
        _currentPath = newPath

        // 记录状态变化（调试用，仅在变化时打印）
        #if DEBUG
            if hasChanged {
                let oldDesc = oldPath?.shortDescription ?? "未知"
                print("📡 NetworkMonitor: 网络状态更新 - \(oldDesc) → \(newPath.shortDescription)")
            }
        #endif

        // 如果有变化，通知用户
        if hasChanged {
            notifyPathUpdate(newPath)
        }
    }

    /// 通知网络路径更新
    ///
    /// **职责**：将网络变化通知分发给所有回调机制
    /// **线程切换**：从监听队列切换到主线程
    ///
    /// **设计考虑**：
    /// - 主线程执行便于 UI 更新
    /// - 使用 weak self 避免循环引用
    /// - 支持多种回调机制（闭包、代理、观察者、通知）
    /// - 检测状态变化，只在实际变化时发送特定通知
    ///
    /// **为什么支持多种回调机制**：
    /// - 闭包：简单场景，快速集成
    /// - 代理：面向对象架构，ViewController 集成
    /// - 观察者：一对多通知，松耦合
    /// - 通知：跨模块通信，全局事件
    ///
    /// - Parameter path: 新的网络路径信息
    private func notifyPathUpdate(_ path: NetworkPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 1. 执行闭包回调
            self.pathUpdateHandler?(path)

            // 2. 通知代理
            self.delegate?.networkMonitor(self, didUpdatePath: path)

            // 3. 通知所有观察者
            self.notifyObservers(path)

            // 4. 发送 NotificationCenter 通知
            self.postNotifications(for: path)

            // 5. 发送 Combine 事件
            // Why: 直接使用 pathPublisher，无需类型转换
            // 好处: 类型安全，编译时检查，避免运行时错误
            if #available(iOS 13.0, macOS 10.15, *) {
                self.pathPublisher.send(path)
            }
        }
    }

    /// 处理监听错误
    ///
    /// **职责**：处理监听过程中的错误情况
    /// **错误类型**：系统资源、权限、配置等问题
    ///
    /// **处理策略**：
    /// 1. 记录错误信息
    /// 2. 更新监听状态
    /// 3. 通知所有回调机制（闭包、代理）
    ///
    /// **为什么通知所有回调**：
    /// - 确保所有监听者都能收到错误信息
    /// - 允许不同模块采取不同的错误处理策略
    ///
    /// - Parameter error: 错误信息
    private func handleError(_ error: Error) {
        print("❌ NetworkMonitor: 监听错误 - \(error.localizedDescription)")

        // 更新状态
        _isMonitoring = false

        // 切换到主线程通知错误
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 1. 执行闭包回调
            self.errorHandler?(error)

            // 2. 通知代理
            self.delegate?.networkMonitor(self, didEncounterError: error)
        }
    }

    // MARK: - 观察者模式支持

    /// 添加观察者
    ///
    /// **设计模式**：观察者模式（Observer Pattern）
    ///
    /// **为什么使用观察者模式**：
    /// - 支持一对多通知，多个组件可以同时监听网络变化
    /// - 松耦合设计，观察者和被观察者互不依赖
    /// - 自动内存管理，使用 weak 引用避免循环引用
    ///
    /// **线程安全**：
    /// - 使用 observersLock 保护观察者集合
    /// - NSHashTable.weakObjects() 自动管理 weak 引用
    ///
    /// **使用场景**：
    /// - 多个 ViewController 需要监听网络变化
    /// - 跨模块的网络状态同步
    /// - 不想使用代理或通知的场景
    ///
    /// **使用示例**：
    /// ```swift
    /// class MyObserver: NetworkPathObserver {
    ///     func networkPathDidChange(_ path: NetworkPath) {
    ///         print("网络变化: \(path.connectionType)")
    ///     }
    /// }
    ///
    /// let observer = MyObserver()
    /// NetworkMonitor.shared.addObserver(observer)
    /// ```
    ///
    /// - Parameter observer: 遵守 NetworkPathObserver 协议的观察者
    public func addObserver(_ observer: NetworkPathObserver) {
        observersLock.lock()
        defer { observersLock.unlock() }

        observers.add(observer as AnyObject)
        print("📝 NetworkMonitor: 添加观察者，当前观察者数量: \(observers.count)")
    }

    /// 移除观察者
    ///
    /// **职责**：从观察者集合中移除指定的观察者
    ///
    /// **为什么需要手动移除**：
    /// - 虽然使用 weak 引用，但显式移除可以立即停止接收通知
    /// - 在观察者生命周期结束前主动清理
    /// - 避免不必要的回调执行
    ///
    /// **使用场景**：
    /// - ViewController 的 deinit 或 viewWillDisappear
    /// - 临时监听场景结束时
    ///
    /// **使用示例**：
    /// ```swift
    /// deinit {
    ///     NetworkMonitor.shared.removeObserver(self)
    /// }
    /// ```
    ///
    /// - Parameter observer: 要移除的观察者
    public func removeObserver(_ observer: NetworkPathObserver) {
        observersLock.lock()
        defer { observersLock.unlock() }

        observers.remove(observer as AnyObject)
        print("🗑️ NetworkMonitor: 移除观察者，当前观察者数量: \(observers.count)")
    }

    /// 通知所有观察者
    ///
    /// **职责**：遍历所有观察者并调用其回调方法
    ///
    /// **线程安全**：
    /// - 使用 observersLock 保护读取操作
    /// - 在主线程执行（调用者已在主线程）
    ///
    /// **为什么使用 allObjects**：
    /// - NSHashTable 的 allObjects 返回当前所有有效对象
    /// - weak 引用已释放的对象会自动从集合中移除
    ///
    /// **为什么使用 for case let**：
    /// - 类型安全的遍历，只处理符合协议的对象
    /// - 过滤掉可能的 nil 或类型不匹配的对象
    ///
    /// - Parameter path: 新的网络路径信息
    private func notifyObservers(_ path: NetworkPath) {
        observersLock.lock()
        let allObservers = observers.allObjects
        observersLock.unlock()

        // 遍历所有观察者并通知
        for case let observer as NetworkPathObserver in allObservers {
            observer.networkPathDidChange(path)
        }
    }

    // MARK: - NotificationCenter 支持

    /// 发送网络状态变化通知
    ///
    /// **职责**：通过 NotificationCenter 发送各种网络状态变化通知
    ///
    /// **为什么使用 NotificationCenter**：
    /// - 全局事件广播，任何模块都可以监听
    /// - 松耦合，发送者和接收者完全解耦
    /// - 支持跨模块通信
    ///
    /// **通知类型**：
    /// - networkPathDidChange: 网络路径变化（总是发送）
    /// - networkDidBecomeAvailable/Unavailable: 可用性变化
    /// - networkQualityDidChange: 质量变化
    /// - connectionTypeDidChange: 连接类型变化
    ///
    /// **为什么检测变化**：
    /// - 避免发送重复通知
    /// - 减少不必要的处理开销
    /// - 只在实际变化时通知，提高效率
    ///
    /// **UserInfo 内容**：
    /// - networkPath: 当前网络路径
    /// - previousPath: 前一个网络路径（如果有）
    /// - monitor: 监听器实例
    ///
    /// - Parameter path: 新的网络路径信息
    private func postNotifications(for path: NetworkPath) {
        var userInfo: [String: Any] = [
            NetworkNotificationKeys.networkPath: path,
            NetworkNotificationKeys.monitor: self,
        ]

        // 添加前一个路径信息（如果有）
        if let previous = previousPath {
            userInfo[NetworkNotificationKeys.previousPath] = previous
        }

        // 1. 总是发送路径变化通知
        NotificationCenter.default.post(
            name: .networkPathDidChange,
            object: self,
            userInfo: userInfo
        )

        // 2. 检测可用性变化
        if let previous = previousPath {
            let wasAvailable = previous.isNetworkAvailable
            let isAvailable = path.isNetworkAvailable

            if wasAvailable != isAvailable {
                let notificationName: Notification.Name =
                    isAvailable ? .networkDidBecomeAvailable : .networkDidBecomeUnavailable
                NotificationCenter.default.post(
                    name: notificationName,
                    object: self,
                    userInfo: userInfo
                )
            }

            // 3. 检测质量变化
            if previous.quality != path.quality {
                var qualityUserInfo = userInfo
                qualityUserInfo[NetworkNotificationKeys.networkQuality] = path.quality
                qualityUserInfo[NetworkNotificationKeys.previousQuality] = previous.quality

                NotificationCenter.default.post(
                    name: .networkQualityDidChange,
                    object: self,
                    userInfo: qualityUserInfo
                )
            }

            // 4. 检测连接类型变化
            if previous.connectionType != path.connectionType {
                var typeUserInfo = userInfo
                typeUserInfo[NetworkNotificationKeys.connectionType] = path.connectionType
                typeUserInfo[NetworkNotificationKeys.previousType] = previous.connectionType

                NotificationCenter.default.post(
                    name: .connectionTypeDidChange,
                    object: self,
                    userInfo: typeUserInfo
                )
            }
        } else {
            // 首次获取网络状态，如果可用则发送可用通知
            if path.isNetworkAvailable {
                NotificationCenter.default.post(
                    name: .networkDidBecomeAvailable,
                    object: self,
                    userInfo: userInfo
                )
            }
        }

        // 更新前一个路径，用于下次变化检测
        previousPath = path
    }

    // MARK: - Async/Await 支持

    /// 异步网络路径更新流
    ///
    /// **设计模式**：异步序列（Async Sequence）
    ///
    /// **为什么使用 AsyncStream**：
    /// - 提供现代的 async/await 接口
    /// - 支持 for-await-in 循环遍历
    /// - 自动处理背压和取消
    /// - 符合 Swift 并发最佳实践
    ///
    /// **生命周期管理**：
    /// - 使用 continuation.onTermination 清理资源
    /// - 订阅者取消时自动停止接收更新
    /// - 避免内存泄漏
    ///
    /// **线程安全**：
    /// - 在主线程接收值
    /// - 符合 Swift 并发的 actor 隔离
    ///
    /// **使用场景**：
    /// - 等待网络状态变化
    /// - 监听网络质量改善
    /// - 异步任务依赖网络状态
    ///
    /// **使用示例**：
    /// ```swift
    /// Task {
    ///     for await path in NetworkMonitor.shared.pathUpdates {
    ///         print("网络变化: \(path.connectionType)")
    ///         if path.quality >= .good {
    ///             break
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// **可用性**：iOS 13.0+, macOS 10.15+
    @available(iOS 13.0, macOS 10.15, *)
    public var pathUpdates: AsyncStream<NetworkPath> {
        AsyncStream { continuation in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // 创建闭包处理器
                let handler: PathUpdateHandler = { path in
                    continuation.yield(path)
                }

                // 保存当前的处理器（如果有）
                let previousHandler = self.pathUpdateHandler

                // 设置新的处理器（链式调用）
                self.pathUpdateHandler = { path in
                    // 先调用之前的处理器
                    previousHandler?(path)
                    // 再调用新的处理器
                    handler(path)
                }

                // 清理资源
                // Why: 使用 @Sendable 闭包确保线程安全，在 onTermination 回调中恢复之前的处理器
                // Swift 6 并发要求: 内层 Task 必须显式捕获 self，避免隐式捕获导致的并发安全问题
                continuation.onTermination = { @Sendable [weak self] _ in
                    Task { @MainActor [weak self, previousHandler] in
                        // 恢复之前的处理器
                        // Why: 显式捕获 [weak self] 符合 Swift 6 并发安全要求
                        // 好处: 避免循环引用，明确表达对 self 的依赖关系
                        self?.pathUpdateHandler = previousHandler
                    }
                }
            }
        }
    }

    /// 等待网络可用
    ///
    /// **功能**：异步等待网络变为可用状态
    ///
    /// **为什么需要这个方法**：
    /// - 简化等待网络的代码
    /// - 支持超时控制
    /// - 提供清晰的错误处理
    ///
    /// **超时处理**：
    /// - 如果指定超时时间，超时后抛出 timeout 错误
    /// - 如果不指定超时，将无限等待
    ///
    /// **使用场景**：
    /// - 应用启动时等待网络
    /// - 网络请求前确保网络可用
    /// - 离线模式切换到在线模式
    ///
    /// **使用示例**：
    /// ```swift
    /// do {
    ///     try await NetworkMonitor.shared.waitForNetwork(timeout: 30.0)
    ///     performNetworkRequest()
    /// } catch {
    ///     showOfflineMessage()
    /// }
    /// ```
    ///
    /// **可用性**：iOS 13.0+, macOS 10.15+
    ///
    /// - Parameter timeout: 超时时间（秒），nil 表示无限等待
    /// - Throws: NetworkMonitorError.timeout 如果超时
    @available(iOS 13.0, macOS 10.15, *)
    public func waitForNetwork(timeout: TimeInterval? = nil) async throws {
        // 如果已经可用，直接返回
        guard !isNetworkAvailable else { return }

        // 创建等待任务
        let waitTask = Task {
            for await path in pathUpdates {
                if path.isNetworkAvailable {
                    return
                }
            }
        }

        // 如果指定了超时时间
        if let timeout = timeout {
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw NetworkMonitorError.timeout(duration: timeout)
            }

            // 等待任一任务完成
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await timeoutTask.value }
                    group.addTask { await waitTask.value }

                    // 等待第一个完成的任务
                    try await group.next()

                    // 取消其他任务
                    group.cancelAll()
                }
            } catch {
                waitTask.cancel()
                timeoutTask.cancel()
                throw error
            }
        } else {
            // 无限等待
            await waitTask.value
        }
    }

    /// 等待 WiFi 连接可用
    ///
    /// **功能**：异步等待 WiFi 网络连接可用
    ///
    /// **为什么需要这个方法**：
    /// - 大文件下载前等待 WiFi，节省用户流量费用
    /// - 高质量媒体播放前等待 WiFi，提供更好的体验
    /// - 避免在蜂窝网络下执行高流量操作
    ///
    /// **超时处理**：
    /// - 如果指定超时时间，超时后抛出 timeout 错误
    /// - 如果不指定超时，将无限等待
    ///
    /// **使用场景**：
    /// - 大文件下载前等待 WiFi
    /// - 高质量视频播放前等待 WiFi
    /// - 云同步前等待 WiFi
    /// - 应用更新前等待 WiFi
    ///
    /// **使用示例**：
    /// ```swift
    /// do {
    ///     try await NetworkMonitor.shared.waitForWiFi(timeout: 60.0)
    ///     startLargeFileDownload()
    /// } catch NetworkMonitorError.timeout {
    ///     // 询问用户是否使用蜂窝网络
    ///     if await askUserToUseCellular() {
    ///         startLargeFileDownload()
    ///     }
    /// }
    /// ```
    ///
    /// **可用性**：iOS 13.0+, macOS 10.15+
    ///
    /// - Parameter timeout: 超时时间（秒），nil 表示无限等待
    /// - Throws: NetworkMonitorError.timeout 如果超时
    @available(iOS 13.0, macOS 10.15, *)
    public func waitForWiFi(timeout: TimeInterval? = nil) async throws {
        // Why: 检查当前是否已经是 WiFi 连接
        // 好处：避免不必要的等待，提高响应速度
        guard connectionType != .wifi else { return }

        // Why: 创建等待任务，监听网络变化直到 WiFi 可用
        // 好处：使用 AsyncStream 提供清晰的异步接口
        let waitTask = Task {
            for await path in pathUpdates {
                if path.connectionType == .wifi {
                    return
                }
            }
        }

        // Why: 支持超时控制，避免无限等待
        // 好处：提供更好的用户体验，允许用户选择其他方案
        if let timeout = timeout {
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw NetworkMonitorError.timeout(duration: timeout)
            }

            // Why: 使用 TaskGroup 并发等待，任一任务完成即返回
            // 好处：WiFi 可用或超时都能及时响应
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask { try await timeoutTask.value }
                    group.addTask { await waitTask.value }

                    // 等待第一个完成的任务
                    try await group.next()

                    // 取消其他任务
                    group.cancelAll()
                }
            } catch {
                // Why: 确保所有任务都被取消，避免资源泄漏
                waitTask.cancel()
                timeoutTask.cancel()
                throw error
            }
        } else {
            // 无限等待 WiFi 可用
            await waitTask.value
        }
    }

    // MARK: - 生命周期管理

    /// 析构方法
    ///
    /// **职责**：确保监听器正确停止，释放系统资源
    /// **重要性**：防止内存泄漏和资源占用
    deinit {
        stopMonitoring()
        print("🗑️ NetworkMonitor: 实例已释放")
    }
}

// MARK: - 便利方法

extension NetworkMonitor {
    /// 快速检查网络是否可用
    ///
    /// **用途**：提供简单的网络可用性检查
    /// **返回值**：当前网络是否可用，未开始监听时返回 false
    ///
    /// **使用示例**：
    /// ```swift
    /// if NetworkMonitor.shared.isNetworkAvailable {
    ///     performNetworkRequest()
    /// } else {
    ///     showOfflineMessage()
    /// }
    /// ```
    public var isNetworkAvailable: Bool {
        return currentPath?.isNetworkAvailable ?? false
    }

    /// 获取当前连接类型
    ///
    /// **返回值**：当前的连接类型，未开始监听时返回 unavailable
    public var connectionType: ConnectionType {
        return currentPath?.connectionType ?? .unavailable
    }

    /// 获取当前网络质量
    ///
    /// **返回值**：当前的网络质量等级，未开始监听时返回 poor
    public var networkQuality: NetworkQuality {
        return currentPath?.quality ?? .poor
    }
}

// MARK: - 调试支持

#if DEBUG
    extension NetworkMonitor {
        /// 打印当前网络状态（仅调试版本）
        ///
        /// **用途**：开发调试时快速查看网络状态
        public func printCurrentStatus() {
            guard let path = currentPath else {
                print("🔍 NetworkMonitor: 未获取到网络状态（可能未开始监听）")
                return
            }

            print("🔍 NetworkMonitor 当前状态:")
            print("   连接类型: \(path.connectionType.displayName)")
            print("   网络质量: \(path.quality.displayName)")
            print("   是否可用: \(path.isNetworkAvailable ? "是" : "否")")
            print("   是否昂贵: \(path.isExpensive ? "是" : "否")")
            print("   是否受限: \(path.isConstrained ? "是" : "否")")
            print("   详细信息: \(path.detailedDescription)")
        }

        /// 模拟网络状态变化（仅调试版本）
        ///
        /// **用途**：测试时模拟网络状态变化
        /// **注意**：仅用于开发测试，不会影响实际网络监听
        ///
        /// - Parameter mockPath: 模拟的网络路径
        public func simulatePathUpdate(_ mockPath: NetworkPath) {
            print("🎭 NetworkMonitor: 模拟网络状态变化")
            notifyPathUpdate(mockPath)
        }
    }
#endif

// MARK: - Singleton Support

/// 单例模式扩展
///
/// **设计理念**：
/// - 提供全局共享实例，简化常见使用场景
/// - 支持特定接口类型的专用单例（WiFi、蜂窝）
/// - 提供工厂方法，支持自定义实例创建
/// - 不破坏依赖注入和测试能力
///
/// **为什么需要多个单例**：
/// - shared: 通用监听器，监听所有网络接口
/// - wifiMonitor: WiFi 专用监听器，只关心 WiFi 状态
/// - cellularMonitor: 蜂窝专用监听器，只关心蜂窝网络状态
///
/// **好处**：
/// - 简化常见使用场景的代码
/// - 避免重复创建监听器实例
/// - 提供语义化的访问方式
/// - 支持特定场景的优化
extension NetworkMonitor {

    // MARK: - 专用接口类型单例

    /// WiFi 专用监听器单例
    ///
    /// **用途**：仅监听 WiFi 接口的网络变化
    ///
    /// **使用场景**：
    /// - 应用只在 WiFi 下执行某些操作（如大文件下载）
    /// - 需要区分 WiFi 和蜂窝网络的场景
    /// - 优化电量消耗，只关心 WiFi 状态
    ///
    /// **为什么这样设计**：
    /// - 使用 lazy static let 确保线程安全
    /// - 独立的监听器实例，不影响 shared 实例
    /// - 自动管理生命周期，无需手动释放
    /// - 只监听 WiFi 接口，过滤其他网络类型的变化
    ///
    /// **好处**：
    /// - 减少不必要的回调，提高性能
    /// - 避免蜂窝网络变化的干扰
    /// - 更精确的 WiFi 状态监控
    ///
    /// **使用示例**：
    /// ```swift
    /// NetworkMonitor.wifiMonitor.startMonitoring()
    /// NetworkMonitor.wifiMonitor.pathUpdateHandler = { path in
    ///     if path.connectionType == .wifi {
    ///         startLargeDownload()
    ///     }
    /// }
    /// ```
    public static let wifiMonitor: NetworkMonitor = {
        return NetworkMonitor(requiredInterfaceType: .wifi)
    }()

    /// 蜂窝网络专用监听器单例
    ///
    /// **用途**：仅监听蜂窝网络接口的变化
    ///
    /// **使用场景**：
    /// - 监控蜂窝网络流量使用
    /// - 蜂窝网络下的特殊处理逻辑
    /// - 流量统计和提醒功能
    ///
    /// **为什么需要独立的蜂窝监听器**：
    /// - 避免 WiFi 变化的干扰
    /// - 精确监控蜂窝网络状态
    /// - 支持流量管理功能
    /// - 只监听蜂窝接口，过滤其他网络类型的变化
    ///
    /// **好处**：
    /// - 减少不必要的回调，提高性能
    /// - 更精确的蜂窝网络状态监控
    /// - 支持流量统计和提醒
    ///
    /// **使用示例**：
    /// ```swift
    /// NetworkMonitor.cellularMonitor.startMonitoring()
    /// NetworkMonitor.cellularMonitor.pathUpdateHandler = { path in
    ///     if path.connectionType == .cellular {
    ///         showDataUsageWarning()
    ///     }
    /// }
    /// ```
    public static let cellularMonitor: NetworkMonitor = {
        return NetworkMonitor(requiredInterfaceType: .cellular)
    }()

    // MARK: - 工厂方法

    /// 创建指定接口类型的监听器
    ///
    /// **用途**：创建监听特定网络接口类型的监听器实例
    ///
    /// **参数说明**：
    /// - interfaceType: 要监听的接口类型（wifi, cellular, wiredEthernet, loopback, other）
    ///
    /// **返回值**：新的监听器实例（非单例）
    ///
    /// **为什么需要工厂方法**：
    /// - 支持动态创建监听器
    /// - 灵活指定监听的接口类型
    /// - 不影响全局单例
    ///
    /// **注意事项**：
    /// - 返回的是新实例，需要手动管理生命周期
    /// - 使用完毕后应调用 stopMonitoring() 释放资源
    /// - 避免创建过多实例造成资源浪费
    ///
    /// **好处**：
    /// - 支持依赖注入，便于测试
    /// - 允许创建多个独立的监听器实例
    /// - 提供语义化的创建方式
    ///
    /// **使用示例**：
    /// ```swift
    /// let wifiMonitor = NetworkMonitor.monitor(for: .wifi)
    /// wifiMonitor.startMonitoring()
    /// wifiMonitor.pathUpdateHandler = { path in
    ///     print("WiFi 状态: \(path.status)")
    /// }
    /// ```
    ///
    /// - Parameter interfaceType: 要监听的接口类型
    /// - Returns: 新的监听器实例
    public static func monitor(for interfaceType: NWInterface.InterfaceType) -> NetworkMonitor {
        return NetworkMonitor(requiredInterfaceType: interfaceType)
    }

    /// 创建通用监听器
    ///
    /// **用途**：创建监听所有网络接口的监听器实例
    ///
    /// **返回值**：新的监听器实例（非单例）
    ///
    /// **为什么需要这个方法**：
    /// - 支持依赖注入，便于测试
    /// - 允许创建多个独立的监听器实例
    /// - 提供语义化的创建方式
    ///
    /// **使用场景**：
    /// - 单元测试中创建独立的监听器实例
    /// - 需要多个独立监听器的复杂场景
    /// - 依赖注入架构
    ///
    /// **使用示例**：
    /// ```swift
    /// class NetworkService {
    ///     private let monitor: NetworkMonitoring
    ///
    ///     init(monitor: NetworkMonitoring = NetworkMonitor.universalMonitor()) {
    ///         self.monitor = monitor
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: 新的监听器实例
    public static func universalMonitor() -> NetworkMonitor {
        return NetworkMonitor()
    }
}

// MARK: - Convenience Access

/// 便捷访问扩展
///
/// **设计目的**：
/// - 提供全局网络状态的快速访问方式
/// - 简化常见查询操作的代码
/// - 提高代码可读性
///
/// **为什么需要便捷方法**：
/// - 避免重复的 `NetworkMonitor.shared.currentPath?.xxx` 代码
/// - 提供语义化的全局状态查询
/// - 简化条件判断代码
///
/// **好处**：
/// - 代码更简洁
/// - 意图更清晰
/// - 减少样板代码
extension NetworkMonitor {

    /// 全局网络可用性
    ///
    /// **用途**：快速检查全局网络是否可用
    ///
    /// **返回值**：true 表示网络可用，false 表示不可用
    ///
    /// **为什么这样设计**：
    /// - 最常见的网络状态查询
    /// - 简化条件判断代码
    /// - 提供清晰的语义
    ///
    /// **使用示例**：
    /// ```swift
    /// if NetworkMonitor.isGlobalNetworkAvailable {
    ///     performNetworkRequest()
    /// } else {
    ///     showOfflineMessage()
    /// }
    /// ```
    public static var isGlobalNetworkAvailable: Bool {
        return shared.isNetworkAvailable
    }

    /// 全局连接类型
    ///
    /// **用途**：快速获取全局网络连接类型
    ///
    /// **返回值**：当前的连接类型（wifi, cellular, wiredEthernet, unavailable）
    ///
    /// **使用场景**：
    /// - 根据连接类型调整应用行为
    /// - 显示网络类型图标
    /// - 流量统计和提醒
    ///
    /// **使用示例**：
    /// ```swift
    /// switch NetworkMonitor.globalConnectionType {
    /// case .wifi:
    ///     enableHDVideo()
    /// case .cellular:
    ///     showDataUsageWarning()
    /// default:
    ///     showOfflineMode()
    /// }
    /// ```
    public static var globalConnectionType: ConnectionType {
        return shared.connectionType
    }

    /// 全局网络质量
    ///
    /// **用途**：快速获取全局网络质量评估
    ///
    /// **返回值**：当前的网络质量等级（poor, fair, good, excellent）
    ///
    /// **使用场景**：
    /// - 根据网络质量调整媒体质量
    /// - 动态调整数据传输策略
    /// - 显示网络质量指示器
    ///
    /// **使用示例**：
    /// ```swift
    /// switch NetworkMonitor.globalNetworkQuality {
    /// case .excellent:
    ///     enableHDVideo()
    /// case .good:
    ///     enableSDVideo()
    /// default:
    ///     enableLowQualityMode()
    /// }
    /// ```
    public static var globalNetworkQuality: NetworkQuality {
        return shared.networkQuality
    }
}
