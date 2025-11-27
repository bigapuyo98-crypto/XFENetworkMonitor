import UIKit

/// 离线模式处理视图控制器
///
/// **功能**：演示如何优雅地处理离线模式
///
/// **设计理念**：
/// - 网络断开时显示离线横幅
/// - 自动暂停网络请求
/// - 网络恢复时自动重试
///
/// **为什么这样设计**：
/// - 提供清晰的离线状态反馈
/// - 避免无效的网络请求
/// - 自动恢复提升用户体验
///
/// **使用方法**：
/// ```swift
/// let vc = OfflineModeViewController()
/// navigationController?.pushViewController(vc, animated: true)
/// ```
class OfflineModeViewController: UIViewController {
    
    // MARK: - UI 组件
    
    /// 离线横幅
    private let offlineBanner: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    private let offlineBannerLabel: UILabel = {
        let label = UILabel()
        label.text = "网络未连接"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 内容视图
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.text = "内容加载中..."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 重试按钮
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重试", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    /// 活动指示器
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - 属性
    
    private let monitor = NetworkMonitor.shared
    private var isLoading = false
    private var offlineBannerTopConstraint: NSLayoutConstraint!
    
    // MARK: - 生命周期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNetworkMonitoring()
        loadContent()
        monitor.pathUpdateHandler
    }
    
    deinit {
        monitor.removeObserver(self)
        monitor.stopMonitoring()
    }
    
    // MARK: - UI 设置
    
    private func setupUI() {
        title = "离线模式处理"
        view.backgroundColor = .systemBackground
        
        // 添加子视图
        view.addSubview(offlineBanner)
        offlineBanner.addSubview(offlineBannerLabel)
        view.addSubview(contentLabel)
        view.addSubview(retryButton)
        view.addSubview(activityIndicator)
        
        // 离线横幅约束
        offlineBannerTopConstraint = offlineBanner.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: -50
        )
        
        NSLayoutConstraint.activate([
            // 离线横幅
            offlineBannerTopConstraint,
            offlineBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            offlineBanner.heightAnchor.constraint(equalToConstant: 50),
            
            offlineBannerLabel.centerXAnchor.constraint(equalTo: offlineBanner.centerXAnchor),
            offlineBannerLabel.centerYAnchor.constraint(equalTo: offlineBanner.centerYAnchor),
            
            // 内容标签
            contentLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            contentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // 重试按钮
            retryButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 20),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 活动指示器
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 按钮事件
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
    }
    
    private func setupNetworkMonitoring() {
        // 使用观察者模式
        monitor.addObserver(self)
        monitor.startMonitoring()
    }
    
    // MARK: - 网络请求
    
    /// 加载内容
    ///
    /// **为什么检查网络状态**：
    /// - 避免在离线时发起无效请求
    /// - 提供即时的用户反馈
    /// - 节省系统资源
    private func loadContent() {
        guard !isLoading else { return }
        
        // 检查网络状态
        guard monitor.isNetworkAvailable else {
            showOfflineMessage()
            return
        }
        
        isLoading = true
        activityIndicator.startAnimating()
        contentLabel.text = "加载中..."
        retryButton.isHidden = true
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            self?.activityIndicator.stopAnimating()
            self?.contentLabel.text = "内容加载成功！\n\n这是一个演示如何处理离线模式的示例。\n\n尝试断开网络连接，观察离线横幅的显示。"
        }
    }
    
    private func showOfflineMessage() {
        activityIndicator.stopAnimating()
        contentLabel.text = "网络未连接\n\n请检查网络连接后重试"
        retryButton.isHidden = false
    }
    
    @objc private func retryButtonTapped() {
        loadContent()
    }
    
    // MARK: - 离线横幅动画
    
    /// 显示离线横幅
    ///
    /// **为什么使用动画**：
    /// - 提供平滑的视觉过渡
    /// - 吸引用户注意
    /// - 提升用户体验
    private func showOfflineBanner() {
        offlineBannerTopConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.offlineBanner.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    /// 隐藏离线横幅
    private func hideOfflineBanner() {
        offlineBannerTopConstraint.constant = -50
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.offlineBanner.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - NetworkPathObserver

extension OfflineModeViewController: NetworkPathObserver {
    func networkPathDidChange(_ path: NetworkPath) {
        DispatchQueue.main.async {
            if path.isNetworkAvailable {
                // 网络恢复
                self.hideOfflineBanner()
                
                // 如果之前加载失败，自动重试
                if !self.isLoading && self.contentLabel.text?.contains("网络未连接") == true {
                    self.loadContent()
                }
            } else {
                // 网络断开
                self.showOfflineBanner()
                
                // 如果正在加载，取消加载
                if self.isLoading {
                    self.isLoading = false
                    self.activityIndicator.stopAnimating()
                    self.showOfflineMessage()
                }
            }
        }
    }
}

