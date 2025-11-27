Pod::Spec.new do |s|
  # 基本信息
  s.name             = 'XFENetworkMonitor'
  s.version          = '1.0.2'
  s.summary          = '强大的 iOS 网络监控框架，支持实时网络状态监听、质量评估和多种回调机制'
  
  # 详细描述
  s.description      = <<-DESC
  XFENetworkMonitor 是一个功能强大、易于使用的 iOS 网络监控框架。
  
  主要特性：
  • 实时网络状态监听（WiFi、蜂窝网络、有线网络等）
  • 智能网络质量评估（优秀、良好、一般、差）
  • 6 种回调机制（闭包、代理、观察者、通知、Combine、AsyncStream）
  • 完整的 Swift 并发支持（async/await）
  • 线程安全设计
  • 低功耗优化
  • 完善的文档和示例代码
  
  适用场景：
  • 网络状态实时监控
  • 自适应内容加载
  • 离线模式切换
  • 网络质量优化
  • 用户体验提升
                       DESC
  
  # 主页和文档
  s.homepage         = 'https://codeup.aliyun.com/68be51c2479007fe862e73cb/xtool/XFENetworkMonitor'
  
  # 许可证
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  
  # 作者信息
  s.author           = { 'XFE Team' => 'xfe@example.com' }
  
  # 源代码仓库
  s.source           = { 
    :git => 'git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git', 
    :tag => s.version.to_s 
  }
  
  # 平台支持
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  
  # Swift 版本
  s.swift_version = '5.9'
  
  # 源文件配置
  # 只包含核心模块，不包含示例代码
  s.source_files = 'Sources/NetworkMonitor/**/*.{swift,h,m}'
  
  # 公开头文件（如果有 Objective-C 代码）
  # s.public_header_files = 'Sources/NetworkMonitor/**/*.h'
  
  # 框架依赖
  s.frameworks = 'Foundation', 'Network', 'Combine'
  
  # 第三方依赖（当前项目无第三方依赖）
  # s.dependency 'Alamofire', '~> 5.0'
  
  # 资源文件（如果有）
  # s.resources = 'Sources/NetworkMonitor/Resources/**/*'
  
  # 模块化配置
  s.module_name = 'XFENetworkMonitor'
  
  # 要求 ARC
  s.requires_arc = true
  
  # 文档 URL
  # s.documentation_url = 'https://your-docs-url.com'
  
  # 截图（可选，用于 CocoaPods 网站展示）
  # s.screenshots = ['https://example.com/screenshot1.png']
  
  # 社交媒体（可选）
  # s.social_media_url = 'https://twitter.com/yourhandle'
end
