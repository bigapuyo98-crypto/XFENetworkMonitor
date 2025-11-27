# XFENetworkMonitor 发布指南

本文档详细说明如何将 XFENetworkMonitor 发布到 CocoaPods 和通过 SPM 分发。

---

## 📦 CocoaPods 发布流程

### 前置准备

#### 1. 安装 CocoaPods

```bash
# 检查是否已安装
pod --version

# 如果未安装，执行以下命令
sudo gem install cocoapods
```

#### 2. 注册 CocoaPods Trunk 账号（首次发布需要）

```bash
# 注册账号
pod trunk register your-email@example.com 'Your Name' --description='MacBook Pro'

# 检查邮箱，点击确认链接

# 验证注册
pod trunk me
```

### 发布步骤

#### 步骤 1：验证 Podspec 文件

```bash
# 进入项目目录
cd /path/to/XFENetworkMonitor

# 本地验证（快速）
pod lib lint XFENetworkMonitor.podspec --allow-warnings

# 完整验证（包括远程仓库）
pod spec lint XFENetworkMonitor.podspec --allow-warnings
```

**常见验证错误及解决方案**：

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| `Unable to find a specification` | podspec 文件格式错误 | 检查语法，确保所有字段正确 |
| `The source couldn't be downloaded` | Git 仓库不可访问 | 确保已推送代码并打好 tag |
| `The spec did not pass validation` | 源文件路径错误 | 检查 `s.source_files` 路径 |
| `Swift version mismatch` | Swift 版本不匹配 | 更新 `s.swift_version` |

#### 步骤 2：提交代码并打 Tag

```bash
# 1. 提交所有更改
git add .
git commit -m "Release version 1.0.0"

# 2. 创建 tag（版本号必须与 podspec 中的一致）
git tag 1.0.0

# 3. 推送代码和 tag
git push origin main
git push origin 1.0.0

# 验证 tag
git tag -l
```

#### 步骤 3：发布到 CocoaPods Trunk

```bash
# 发布到 CocoaPods
pod trunk push XFENetworkMonitor.podspec --allow-warnings

# 如果需要跳过验证（不推荐）
# pod trunk push XFENetworkMonitor.podspec --skip-validation
```

**发布过程说明**：
- ✅ 验证 podspec 文件
- ✅ 检查 Git 仓库和 tag
- ✅ 编译源代码
- ✅ 运行测试（如果有）
- ✅ 上传到 CocoaPods CDN

#### 步骤 4：验证发布成功

```bash
# 搜索你的 Pod
pod search XFENetworkMonitor

# 查看 Pod 信息
pod trunk info XFENetworkMonitor

# 在新项目中测试安装
pod init
# 编辑 Podfile，添加 pod 'XFENetworkMonitor'
pod install
```

### 更新版本

当需要发布新版本时：

```bash
# 1. 更新 podspec 中的版本号
# 编辑 XFENetworkMonitor.podspec
# s.version = '1.0.1'

# 2. 提交更改
git add XFENetworkMonitor.podspec
git commit -m "Bump version to 1.0.1"

# 3. 创建新 tag
git tag 1.0.1
git push origin main
git push origin 1.0.1

# 4. 发布新版本
pod trunk push XFENetworkMonitor.podspec --allow-warnings
```

### 删除版本（谨慎操作）

```bash
# 删除指定版本
pod trunk delete XFENetworkMonitor 1.0.0

# 注意：删除后无法恢复，且可能影响依赖此版本的项目
```

---

## 📦 Swift Package Manager (SPM) 发布流程

SPM 不需要注册账号，只需要在 GitHub/GitLab 上托管代码即可。

### 前置准备

#### 1. 确保 Package.swift 文件正确

```bash
# 验证 Package.swift
swift package dump-package

# 构建测试
swift build

# 运行测试
swift test
```

#### 2. 确保项目结构符合 SPM 规范

```
XFENetworkMonitor/
├── Package.swift
├── Sources/
│   └── NetworkMonitor/
│       ├── Core/
│       └── Models/
├── Tests/
│   └── XFENetworkMonitorTests/
└── README.md
```

### 发布步骤

#### 步骤 1：提交代码

```bash
# 1. 提交所有更改
git add .
git commit -m "Release version 1.0.0"

# 2. 推送到远程仓库
git push origin main
```

#### 步骤 2：创建 Release Tag

```bash
# 1. 创建语义化版本 tag
git tag -a 1.0.0 -m "Release version 1.0.0

主要特性：
- 实时网络状态监听
- 智能质量评估
- 6 种回调机制
- Swift 并发支持
"

# 2. 推送 tag
git push origin 1.0.0

# 3. 验证 tag
git tag -l
git show 1.0.0
```

#### 步骤 3：在 Git 平台创建 Release（推荐）

**GitHub 示例**：

1. 访问仓库页面
2. 点击 "Releases" → "Create a new release"
3. 选择刚创建的 tag（1.0.0）
4. 填写 Release 标题：`v1.0.0 - 首次发布`
5. 填写 Release 说明：
   ```markdown
   ## ✨ 新特性
   
   - 🌐 实时网络状态监听
   - 📊 智能网络质量评估
   - 🔄 6 种回调机制（闭包、代理、观察者、通知、Combine、AsyncStream）
   - ⚡️ 完整的 Swift 并发支持
   - 🔒 线程安全设计
   - 🔋 低功耗优化
   
   ## 📦 安装
   
   ### Swift Package Manager
   
   ```swift
   dependencies: [
       .package(url: "https://github.com/yourorg/XFENetworkMonitor.git", from: "1.0.0")
   ]
   ```
   
   ## 📖 文档
   
   详见 [README.md](README.md)
   ```
6. 点击 "Publish release"

**Aliyun Codeup 示例**：

1. 访问项目页面
2. 点击 "发布" → "新建发布"
3. 选择 tag：1.0.0
4. 填写发布标题和说明
5. 点击 "创建发布"

#### 步骤 4：验证 SPM 集成

在新项目中测试：

```bash
# 创建测试项目
mkdir TestSPM
cd TestSPM

# 创建 Package.swift
cat > Package.swift << 'PKGEOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TestSPM",
    platforms: [.iOS(.v13)],
    dependencies: [
        .package(
            url: "git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "TestSPM",
            dependencies: ["XFENetworkMonitor"]
        )
    ]
)
PKGEOF

# 解析依赖
swift package resolve

# 构建
swift build
```

### 更新版本

```bash
# 1. 更新 Package.swift 中的版本信息（如果有）
# 2. 提交更改
git add .
git commit -m "Release version 1.0.1"
git push origin main

# 3. 创建新 tag
git tag -a 1.0.1 -m "Release version 1.0.1

修复：
- 修复 Swift 6 并发警告
- 优化内存管理
"
git push origin 1.0.1

# 4. 在 Git 平台创建新 Release
```

---

## 🔄 版本管理最佳实践

### 语义化版本（Semantic Versioning）

格式：`MAJOR.MINOR.PATCH`

- **MAJOR**（主版本号）：不兼容的 API 变更
- **MINOR**（次版本号）：向后兼容的功能新增
- **PATCH**（修订号）：向后兼容的问题修复

示例：
- `1.0.0` → `1.0.1`：修复 bug
- `1.0.1` → `1.1.0`：新增功能
- `1.1.0` → `2.0.0`：破坏性变更

### 版本发布检查清单

发布前确认：

- [ ] 所有测试通过
- [ ] 文档已更新（README.md、CHANGELOG.md）
- [ ] 版本号已更新（podspec、Package.swift）
- [ ] 代码已提交并推送
- [ ] Tag 已创建并推送
- [ ] Release 说明已编写
- [ ] 示例代码已验证

### CHANGELOG.md 示例

创建 `CHANGELOG.md` 记录版本变更：

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2024-11-27

### Fixed
- 修复 Swift 6 并发警告
- 修复 pathPublisher 类型推断问题

### Changed
- 优化内存管理
- 改进文档

## [1.0.0] - 2024-11-27

### Added
- 首次发布
- 实时网络状态监听
- 智能质量评估
- 6 种回调机制
- Swift 并发支持
```

---

## 🚀 自动化发布（可选）

### 使用 GitHub Actions

创建 `.github/workflows/release.yml`：

```yaml
name: Release

on:
  push:
    tags:
      - '*'

jobs:
  release:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.0'
    
    - name: Install CocoaPods
      run: gem install cocoapods
    
    - name: Validate Podspec
      run: pod lib lint XFENetworkMonitor.podspec --allow-warnings
    
    - name: Publish to CocoaPods
      env:
        COCOAPODS_TRUNK_TOKEN: ${{ secrets.COCOAPODS_TRUNK_TOKEN }}
      run: pod trunk push XFENetworkMonitor.podspec --allow-warnings
    
    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
```

---

## 📊 发布后验证

### CocoaPods

```bash
# 1. 搜索 Pod
pod search XFENetworkMonitor

# 2. 查看详细信息
pod trunk info XFENetworkMonitor

# 3. 在新项目中测试
mkdir TestCocoaPods
cd TestCocoaPods
pod init
# 编辑 Podfile，添加 pod 'XFENetworkMonitor'
pod install
```

### SPM

```bash
# 1. 在 Xcode 中测试
# File > Add Package Dependencies...
# 输入仓库 URL

# 2. 命令行测试
swift package resolve
swift build
```

---

## ❓ 常见问题

### Q1: CocoaPods 验证失败怎么办？

**A**: 检查以下几点：
1. podspec 文件语法是否正确
2. Git tag 是否已推送
3. 源文件路径是否正确
4. Swift 版本是否匹配

### Q2: SPM 无法解析依赖？

**A**: 确认：
1. Package.swift 语法正确
2. Git 仓库可访问
3. Tag 已推送
4. 版本号格式正确（如 1.0.0）

### Q3: 如何撤回已发布的版本？

**A**: 
- **CocoaPods**: `pod trunk delete XFENetworkMonitor 1.0.0`（谨慎操作）
- **SPM**: 删除 Git tag 和 Release（不推荐，可能影响已使用的项目）

### Q4: 如何发布 Beta 版本？

**A**:
- **CocoaPods**: 使用版本号如 `1.0.0-beta.1`
- **SPM**: 使用 tag 如 `1.0.0-beta.1`

---

## 📚 参考资源

- [CocoaPods 官方文档](https://guides.cocoapods.org/)
- [Swift Package Manager 文档](https://swift.org/package-manager/)
- [语义化版本规范](https://semver.org/lang/zh-CN/)
- [Git Tag 文档](https://git-scm.com/book/zh/v2/Git-基础-打标签)

---

**祝发布顺利！🎉**
