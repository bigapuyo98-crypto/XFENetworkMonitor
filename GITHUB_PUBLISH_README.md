# GitHub 发布说明

## 📦 双仓库策略

本项目采用**双仓库策略**：

### 🔒 阿里云 Codeup（开发仓库）
- **地址**: `git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git`
- **用途**: 完整项目开发
- **内容**: 
  - ✅ 完整源代码
  - ✅ 所有文档（架构、集成示例、发布指南等）
  - ✅ Xcode 项目文件
  - ✅ 测试代码
  - ✅ CocoaPods 配置
  - ✅ 开发脚本

### 🌍 GitHub（公开发布仓库）
- **地址**: `https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git`
- **用途**: 公开发布，供 SPM 集成
- **内容**（精简版）:
  - ✅ README.md
  - ✅ LICENSE
  - ✅ Package.swift
  - ✅ Sources/NetworkMonitor/（核心代码）
  - ✅ Sources/Examples/（示例代码）

---

## 🚀 发布流程

### 1. 在阿里云 Codeup 开发

正常开发、提交、推送到 `origin`（阿里云）：

```bash
git add .
git commit -m "你的提交信息"
git push origin main
```

### 2. 创建版本 Tag

```bash
# 创建 tag
git tag -a 1.0.2 -m "Release version 1.0.2"

# 推送到阿里云
git push origin 1.0.2
```

### 3. 发布到 GitHub

运行发布脚本：

```bash
./publish_to_github.sh
```

脚本会自动：
- ✅ 创建临时分支
- ✅ 删除不需要公开的文件
- ✅ 推送到 GitHub
- ✅ 推送所有 tags
- ✅ 清理临时分支

---

## 📝 手动发布步骤（如果不用脚本）

如果你想手动发布：

```bash
# 1. 创建临时分支
git checkout -b github-release-temp

# 2. 删除不需要的文件
rm -f ARCHITECTURE*.md INTEGRATION_EXAMPLES.md PUBLISHING_GUIDE.md QUICK_START.md
rm -f XFENetworkMonitor.podspec
rm -rf XFENetworkMonitor.xcodeproj
rm -rf XFENetworkMonitor XFENetworkMonitorTests XFENetworkMonitorUITests
rm -rf Sources/docs .build

# 3. 提交
git add -A
git commit -m "Release for GitHub"

# 4. 推送到 GitHub
git push -f github github-release-temp:main
git push github --tags

# 5. 切换回主分支
git checkout main
git branch -D github-release-temp
```

---

## 🔄 工作流程示例

```bash
# 日常开发
git add .
git commit -m "feat: 添加新功能"
git push origin main

# 准备发布新版本
git tag -a 1.0.2 -m "Release 1.0.2"
git push origin 1.0.2

# 发布到 GitHub
./publish_to_github.sh
```

---

## ⚠️ 注意事项

1. **不要直接在 GitHub 仓库修改代码**
   - GitHub 仓库是只读发布仓库
   - 所有开发都在阿里云 Codeup 进行

2. **发布前确保代码已提交**
   - 脚本会检查未提交的更改
   - 建议先推送到阿里云，再发布到 GitHub

3. **版本号管理**
   - 使用语义化版本（Semantic Versioning）
   - 格式：`MAJOR.MINOR.PATCH`（如 1.0.2）

4. **GitHub 仓库需要先创建**
   - 确保 `https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git` 已创建
   - 可以是空仓库

---

## 📦 用户集成方式

用户通过 GitHub 集成（公开）：

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git",
        from: "1.0.1"
    )
]
```

或通过 Xcode：
1. File → Add Package Dependencies...
2. 输入：`https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git`
3. 选择版本

---

## 🎯 优势

✅ **开发仓库保密** - 内部文档、测试代码不公开  
✅ **发布仓库精简** - 用户只下载必要文件  
✅ **版本同步** - 两个仓库使用相同的 tag  
✅ **自动化发布** - 一键脚本完成发布  
✅ **灵活管理** - 可以选择性发布特定版本  

---

## 🔧 远程仓库管理

查看远程仓库：
```bash
git remote -v
```

输出：
```
github  https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git (fetch)
github  https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git (push)
origin  git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git (fetch)
origin  git@codeup.aliyun.com:68be51c2479007fe862e73cb/xtool/XFENetworkMonitor.git (push)
```

- `origin` = 阿里云 Codeup（开发仓库）
- `github` = GitHub（发布仓库）

