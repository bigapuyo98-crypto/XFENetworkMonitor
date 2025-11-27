# NetworkMonitor API 参考文档

> 完整的 API 接口文档

**文档版本**: 1.0  
**最后更新**: 2025-11-27  
**适用版本**: NetworkMonitor 1.0+

---

## 📚 目录

1. [核心协议](#1-核心协议)
2. [核心类](#2-核心类)
3. [数据模型](#3-数据模型)
4. [回调协议](#4-回调协议)
5. [通知](#5-通知)
6. [错误类型](#6-错误类型)

---

## 1. 核心协议

### NetworkMonitoring

网络监测核心协议，定义网络监测的核心接口。

```swift
public protocol NetworkMonitoring: AnyObject {
    // MARK: - 核心属性
    
    /// 当前网络路径信息
    var currentPath: NetworkPath? { get }
    
    /// 是否正在监听
    var isMonitoring: Bool { get }
    
    // MARK: - 核心方法
    
    /// 开始网络监听
    func startMonitoring()
    
    /// 停止网络监听
    func stopMonitoring()
    
    // MARK: - 回调属性
    
    /// 路径更新回调
    var pathUpdateHandler: PathUpdateHandler? { get set }
    
    /// 错误回调
    var errorHandler: NetworkErrorHandler? { get set }
    
    /// 代理
    weak var delegate: NetworkMonitorDelegate? { get set }
    
    // MARK: - 观察者管理
    
    /// 添加观察者
    func addObserver(_ observer: NetworkPathObserver)
    
    /// 移除观察者
    func removeObserver(_ observer: NetworkPathObserver)
    
    // MARK: - Combine 支持
    
    /// 网络路径发布者
    @available(iOS 13.0, macOS 10.15, *)
    var pathPublisher: PassthroughSubject<NetworkPath, Never> { get }
    
    // MARK: - Async/Await 支持
    
    /// 异步网络路径流
    @available(iOS 13.0, macOS 10.15, *)
    var pathUpdates: AsyncStream<NetworkPath> { get }
    
    /// 等待网络可用
    @available(iOS 13.0, macOS 10.15, *)
    func waitForNetwork(timeout: TimeInterval?) async throws
}
```

### 协议扩展提供的便捷属性

```swift
public extension NetworkMonitoring {
    /// 网络是否可用
    var isNetworkAvailable: Bool { get }
    
    /// 当前连接类型
    var connectionType: ConnectionType { get }
    
    /// 当前网络质量
    var networkQuality: NetworkQuality { get }
    
    /// 是否为昂贵网络
    var isExpensiveNetwork: Bool { get }
    
    /// 是否为受限网络
    var isConstrainedNetwork: Bool { get }
    
    /// 是否为 WiFi 连接
    var isWiFiConnection: Bool { get }
    
    /// 是否为蜂窝网络连接
    var isCellularConnection: Bool { get }
    
    /// 是否适合大文件传输
    var isSuitableForLargeTransfers: Bool { get }
    
    /// 是否适合高质量媒体
    var isSuitableForHighQualityMedia: Bool { get }
}
```

---

## 2. 核心类

### NetworkMonitor

网络监测器核心实现类。

```swift
public class NetworkMonitor: NetworkMonitoring {
    // MARK: - 单例
    
    /// 共享实例（通用监听器）
    public static let shared: NetworkMonitor
    
    /// WiFi 专用监听器
    public static let wifiMonitor: NetworkMonitor
    
    /// 蜂窝网络专用监听器
    public static let cellularMonitor: NetworkMonitor
    
    // MARK: - 初始化
    
    /// 创建通用监听器
    public static func universalMonitor() -> NetworkMonitor
    
    /// 创建特定接口类型的监听器
    public init(requiredInterfaceType: NWInterface.InterfaceType? = nil)
    
    // MARK: - 核心方法
    
    /// 开始监听
    public func startMonitoring()
    
    /// 停止监听
    public func stopMonitoring()
    
    // MARK: - 属性
    
    /// 当前网络路径
    public private(set) var currentPath: NetworkPath?
    
    /// 是否正在监听
    public var isMonitoring: Bool { get }
    
    // MARK: - 回调
    
    /// 路径更新回调
    public var pathUpdateHandler: PathUpdateHandler?
    
    /// 错误回调
    public var errorHandler: NetworkErrorHandler?
    
    /// 代理
    public weak var delegate: NetworkMonitorDelegate?
    
    // MARK: - 观察者
    
    public func addObserver(_ observer: NetworkPathObserver)
    public func removeObserver(_ observer: NetworkPathObserver)
    
    // MARK: - Combine
    
    @available(iOS 13.0, macOS 10.15, *)
    public let pathPublisher: PassthroughSubject<NetworkPath, Never>
    
    // MARK: - Async/Await
    
    @available(iOS 13.0, macOS 10.15, *)
    public var pathUpdates: AsyncStream<NetworkPath> { get }
    
    @available(iOS 13.0, macOS 10.15, *)
    public func waitForNetwork(timeout: TimeInterval? = nil) async throws
    
    @available(iOS 13.0, macOS 10.15, *)
    public func waitForWiFi(timeout: TimeInterval? = nil) async throws
}
```

---

## 3. 数据模型

### NetworkPath

网络路径信息结构体（不可变值类型）。

```swift
public struct NetworkPath {
    // MARK: - 基础属性
    
    /// 网络状态
    public let status: NWPath.Status
    
    /// 连接类型
    public let connectionType: ConnectionType
    
    /// 是否为昂贵网络
    public let isExpensive: Bool
    
    /// 是否为受限网络
    public let isConstrained: Bool
    
    /// 支持 IPv4
    public let supportsIPv4: Bool
    
    /// 支持 IPv6
    public let supportsIPv6: Bool
    
    /// 支持 DNS
    public let supportsDNS: Bool
    
    /// 可用接口列表
    public let availableInterfaces: [NWInterface.InterfaceType]
    
    // MARK: - 计算属性
    
    /// 网络是否可用
    public var isNetworkAvailable: Bool { get }
    
    /// 网络质量
    public var quality: NetworkQuality { get }
    
    /// 简短描述
    public var shortDescription: String { get }
}
```
