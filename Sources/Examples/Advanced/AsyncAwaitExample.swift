import Foundation

// Why: 示例文件作为项目的一部分编译，NetworkMonitor 类型在同一模块中
// 好处：无需显式导入，简化示例代码
// 注意：如果作为独立文件使用，需要添加 `import NetworkMonitor`

/// Async/Await 现代并发示例
///
/// **功能**：演示如何使用 async/await 处理网络监听
///
/// **设计理念**：
/// - 使用 async/await 简化异步代码
/// - 使用 AsyncStream 监听网络变化
/// - 支持超时控制
///
/// **为什么使用 async/await**：
/// - 代码更清晰易读
/// - 避免回调地狱
/// - 更好的错误处理
/// - 支持结构化并发
///
/// **使用场景**：
/// - 应用启动时等待网络
/// - 网络请求前确保网络可用
/// - 监听网络状态变化
///
/// **使用方法**：
/// ```swift
/// let example = AsyncAwaitExample()
/// Task {
///     await example.run()
/// }
/// ```
@available(iOS 13.0, macOS 10.15, *)
class AsyncAwaitExample {
    private let monitor = NetworkMonitor.shared
    
    // MARK: - 示例 1: 等待网络可用
    
    /// 等待网络可用（带超时）
    ///
    /// **使用场景**：
    /// - 应用启动时等待网络
    /// - 网络请求前确保网络可用
    ///
    /// **为什么需要超时**：
    /// - 避免无限等待
    /// - 提供用户反馈
    /// - 允许用户手动重试
    func example1_WaitForNetwork() async {
        print("=== 示例 1: 等待网络可用 ===\n")
        
        do {
            print("⏳ 等待网络可用（30 秒超时）...")
            try await monitor.waitForNetwork(timeout: 30.0)
            print("✅ 网络已可用")
            
            // 网络可用后执行操作
            await performNetworkRequest()
            
        } catch NetworkMonitorError.timeout {
            print("❌ 等待网络超时")
            showOfflineMessage()
            
        } catch {
            print("❌ 错误: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 示例 2: 等待特定网络类型
    
    /// 等待 WiFi 连接
    ///
    /// **使用场景**：
    /// - 大文件下载前等待 WiFi
    /// - 高质量媒体播放前等待 WiFi
    ///
    /// **为什么等待 WiFi**：
    /// - 节省用户流量费用
    /// - 提供更好的下载速度
    /// - 避免蜂窝网络限制
    func example2_WaitForWiFi() async {
        print("\n=== 示例 2: 等待 WiFi 连接 ===\n")
        
        do {
            print("⏳ 等待 WiFi 连接（60 秒超时）...")
            try await monitor.waitForWiFi(timeout: 60.0)
            print("✅ WiFi 已连接")
            
            // WiFi 可用后执行大文件下载
            await startLargeFileDownload()
            
        } catch NetworkMonitorError.timeout {
            print("❌ 等待 WiFi 超时")
            
            // 询问用户是否使用蜂窝网络
            if await askUserToUseCellular() {
                await startLargeFileDownload()
            }
            
        } catch {
            print("❌ 错误: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 示例 3: 监听网络变化
    
    /// 使用 AsyncStream 监听网络变化
    ///
    /// **使用场景**：
    /// - 持续监听网络状态
    /// - 等待网络质量达到要求
    ///
    /// **为什么使用 AsyncStream**：
    /// - 提供异步序列
    /// - 支持 for-await-in 语法
    /// - 自动内存管理
    func example3_MonitorNetworkChanges() async {
        print("\n=== 示例 3: 监听网络变化 ===\n")
        
        print("📡 开始监听网络变化...")
        monitor.startMonitoring()
        
        var changeCount = 0
        
        // 使用 for-await-in 监听网络变化
        for await path in monitor.pathUpdates {
            changeCount += 1
            
            print("\n📊 网络变化 #\(changeCount)")
            print("   连接类型: \(path.connectionType.displayName)")
            print("   网络质量: \(path.quality.displayName)")
            print("   是否可用: \(path.isNetworkAvailable)")
            
            // 等待网络质量达到良好
            if path.quality >= .good {
                print("✅ 网络质量达到要求，停止监听")
                break
            }
        }
        
        monitor.stopMonitoring()
    }
    
    // MARK: - 示例 4: 并发等待多个条件
    
    /// 并发等待多个网络条件
    ///
    /// **使用场景**：
    /// - 同时等待多个网络条件
    /// - 实现复杂的网络策略
    ///
    /// **为什么使用并发**：
    /// - 提高效率
    /// - 减少等待时间
    /// - 支持多种网络策略
    func example4_ConcurrentWait() async {
        print("\n=== 示例 4: 并发等待多个条件 ===\n")
        
        print("⏳ 并发等待网络条件...")
        
        // 使用 TaskGroup 并发等待
        await withTaskGroup(of: NetworkCondition.self) { group in
            // 任务 1: 等待网络可用
            group.addTask {
                do {
                    try await self.monitor.waitForNetwork(timeout: 30.0)
                    return .networkAvailable
                } catch {
                    return .timeout
                }
            }
            
            // 任务 2: 等待 WiFi
            group.addTask {
                do {
                    try await self.monitor.waitForWiFi(timeout: 30.0)
                    return .wifiAvailable
                } catch {
                    return .timeout
                }
            }
            
            // 处理第一个完成的任务
            if let firstResult = await group.next() {
                print("✅ 第一个条件满足: \(firstResult)")
                
                // 取消其他任务
                group.cancelAll()
                
                // 根据结果执行操作
                switch firstResult {
                case .networkAvailable:
                    print("   → 网络可用，使用当前网络")
                case .wifiAvailable:
                    print("   → WiFi 可用，使用 WiFi")
                case .timeout:
                    print("   → 超时，进入离线模式")
                }
            }
        }
    }
    
    // MARK: - 示例 5: 重试机制
    
    /// 带重试机制的网络请求
    ///
    /// **使用场景**：
    /// - 网络不稳定时自动重试
    /// - 提高请求成功率
    ///
    /// **为什么需要重试**：
    /// - 网络可能暂时不可用
    /// - 提高用户体验
    /// - 减少用户手动操作
    func example5_RetryMechanism() async {
        print("\n=== 示例 5: 重试机制 ===\n")
        
        let maxRetries = 3
        var attempt = 0
        
        while attempt < maxRetries {
            attempt += 1
            print("🔄 尝试 #\(attempt)/\(maxRetries)")
            
            do {
                // 等待网络可用
                try await monitor.waitForNetwork(timeout: 10.0)
                
                // 执行网络请求
                await performNetworkRequest()
                
                print("✅ 请求成功")
                return
                
            } catch {
                print("❌ 请求失败: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    print("   → 等待 2 秒后重试...")
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                } else {
                    print("   → 达到最大重试次数，放弃")
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func performNetworkRequest() async {
        print("   → 执行网络请求...")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        print("   → 请求完成")
    }
    
    private func startLargeFileDownload() async {
        print("   → 开始大文件下载...")
    }
    
    private func askUserToUseCellular() async -> Bool {
        print("   → 询问用户是否使用蜂窝网络...")
        return false
    }
    
    private func showOfflineMessage() {
        print("   → 显示离线提示")
    }
    
    // MARK: - 运行所有示例
    
    func run() async {
        await example1_WaitForNetwork()
        await example2_WaitForWiFi()
        await example3_MonitorNetworkChanges()
        await example4_ConcurrentWait()
        await example5_RetryMechanism()
    }
}

// MARK: - 辅助类型

@available(iOS 13.0, macOS 10.15, *)
enum NetworkCondition {
    case networkAvailable
    case wifiAvailable
    case timeout
}

