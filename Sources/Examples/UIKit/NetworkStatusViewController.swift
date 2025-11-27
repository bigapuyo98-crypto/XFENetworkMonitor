import UIKit

/// UIKit 网络状态视图控制器
///
/// **功能**：使用代理模式监听网络状态变化并更新 UI
///
/// **设计理念**：
/// - 使用代理模式接收网络状态更新
/// - 使用动画效果提升用户体验
/// - 遵循 UIKit 最佳实践
///
/// **为什么这样设计**：
/// - 代理模式符合 iOS 开发习惯
/// - 动画效果提供视觉反馈
/// - 易于集成到现有 UIKit 项目
///
/// **使用方法**：
/// ```swift
/// let vc = NetworkStatusViewController()
/// navigationController?.pushViewController(vc, animated: true)
/// ```
class NetworkStatusViewController: UIViewController {
    
    // MARK: - UI 组件
    
    /// 状态图标
    private let statusIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// 状态标签
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 详细信息容器
    private let detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    /// 建议标签
    private let suggestionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 属性
    
    private let monitor = NetworkMonitor.shared
    
    // MARK: - 生命周期
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNetworkMonitoring()
    }
    
    deinit {
        // 清理资源
        monitor.delegate = nil
        monitor.stopMonitoring()
    }
    
    // MARK: - UI 设置
    
    private func setupUI() {
        title = "网络状态"
        view.backgroundColor = .systemBackground
        
        // 添加子视图
        view.addSubview(statusIconView)
        view.addSubview(statusLabel)
        view.addSubview(detailsStackView)
        view.addSubview(suggestionLabel)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 状态图标
            statusIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusIconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            statusIconView.widthAnchor.constraint(equalToConstant: 80),
            statusIconView.heightAnchor.constraint(equalToConstant: 80),
            
            // 状态标签
            statusLabel.topAnchor.constraint(equalTo: statusIconView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 详细信息
            detailsStackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            detailsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detailsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 建议标签
            suggestionLabel.topAnchor.constraint(equalTo: detailsStackView.bottomAnchor, constant: 40),
            suggestionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            suggestionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupNetworkMonitoring() {
        // 设置代理
        monitor.delegate = self
        
        // 启动监听
        monitor.startMonitoring()
        
        // 显示当前状态
        if let currentPath = monitor.currentPath {
            updateUI(with: currentPath)
        }
    }
    
    // MARK: - UI 更新
    
    /// 更新 UI（带动画效果）
    ///
    /// **为什么使用动画**：
    /// - 提供视觉反馈
    /// - 提升用户体验
    /// - 使状态变化更明显
    private func updateUI(with path: NetworkPath) {
        // 使用动画更新 UI
        UIView.animate(withDuration: 0.3) {
            // 更新图标
            self.statusIconView.image = self.statusIcon(for: path)
            self.statusIconView.tintColor = self.statusColor(for: path)
            
            // 更新状态文本
            self.statusLabel.text = path.isNetworkAvailable ? "网络已连接" : "网络未连接"
            self.statusLabel.textColor = self.statusColor(for: path)
        }
        
        // 更新详细信息
        updateDetails(with: path)
        
        // 更新建议
        updateSuggestion(with: path)
    }
    
    private func updateDetails(with path: NetworkPath) {
        // 清空现有视图
        detailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加详细信息行
        addDetailRow(label: "连接类型", value: path.connectionType.displayName)
        addDetailRow(label: "网络质量", value: path.quality.displayName)
        addDetailRow(label: "是否昂贵", value: path.isExpensive ? "是" : "否")
        addDetailRow(label: "是否受限", value: path.isConstrained ? "是" : "否")
    }
    
    private func addDetailRow(label: String, value: String) {
        let row = DetailRowView(label: label, value: value)
        detailsStackView.addArrangedSubview(row)
    }
    
    private func updateSuggestion(with path: NetworkPath) {
        if !path.isNetworkAvailable {
            suggestionLabel.text = "请检查网络连接"
        } else if path.isConstrained {
            suggestionLabel.text = "低数据模式已开启，建议减少数据使用"
        } else if path.isExpensive {
            suggestionLabel.text = "当前使用蜂窝网络，可能产生流量费用"
        } else {
            suggestionLabel.text = nil
        }
    }
    
    // MARK: - 辅助方法
    
    private func statusIcon(for path: NetworkPath) -> UIImage? {
        let iconName: String
        if !path.isNetworkAvailable {
            iconName = "wifi.slash"
        } else {
            switch path.connectionType {
            case .wifi: iconName = "wifi"
            case .cellular: iconName = "antenna.radiowaves.left.and.right"
            case .wiredEthernet: iconName = "cable.connector"
            default: iconName = "network"
            }
        }
        return UIImage(systemName: iconName)
    }
    
    private func statusColor(for path: NetworkPath) -> UIColor {
        if !path.isNetworkAvailable { return .systemRed }
        switch path.quality {
        case .excellent: return .systemGreen
        case .good: return .systemBlue
        case .fair: return .systemOrange
        case .poor: return .systemRed
        }
    }
}

// MARK: - NetworkMonitorDelegate

extension NetworkStatusViewController: NetworkMonitorDelegate {
    func networkMonitor(_ monitor: NetworkMonitoring, didUpdatePath path: NetworkPath) {
        // 在主线程更新 UI
        DispatchQueue.main.async {
            self.updateUI(with: path)
        }
    }
}

// MARK: - DetailRowView

/// 详细信息行视图
class DetailRowView: UIView {
    init(label: String, value: String) {
        super.init(frame: .zero)
        setupUI(label: label, value: value)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(label: String, value: String) {
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .secondaryLabel
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 16, weight: .medium)
        valueView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(labelView)
        addSubview(valueView)
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueView.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}

