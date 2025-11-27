#!/bin/bash

# XFENetworkMonitor GitHub 发布脚本
# 用途：将精简版本推送到 GitHub 公开仓库
# 保留：README.md, LICENSE, Package.swift, Sources/

set -e  # 遇到错误立即退出

echo "🚀 开始发布到 GitHub..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 检查是否有未提交的更改
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}⚠️  警告：有未提交的更改${NC}"
    git status -s
    echo ""
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 取消发布"
        exit 1
    fi
fi

# 2. 获取当前版本号
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "未找到版本")
echo -e "${BLUE}📦 当前版本: ${VERSION}${NC}"
echo ""

# 3. 创建临时分支用于发布
TEMP_BRANCH="github-release-temp"
echo -e "${BLUE}🔧 创建临时发布分支: ${TEMP_BRANCH}${NC}"
git checkout -b ${TEMP_BRANCH} 2>/dev/null || git checkout ${TEMP_BRANCH}

# 4. 删除不需要发布的文件
echo -e "${BLUE}🗑️  删除不需要发布的文件...${NC}"

# 删除内部文档（保留 README.md）
rm -f ARCHITECTURE.md
rm -f ARCHITECTURE_SUMMARY.md
rm -f INTEGRATION_EXAMPLES.md
rm -f PUBLISHING_GUIDE.md
rm -f QUICK_START.md

# 删除 CocoaPods 配置
rm -f XFENetworkMonitor.podspec

# 删除 Xcode 项目
rm -rf XFENetworkMonitor.xcodeproj

# 删除测试目录
rm -rf XFENetworkMonitor
rm -rf XFENetworkMonitorTests
rm -rf XFENetworkMonitorUITests

# 删除内部文档目录
rm -rf Sources/docs

# 删除构建产物
rm -rf .build

# 删除备份文件
find . -name "*.backup" -delete

# 删除 .DS_Store
find . -name ".DS_Store" -delete

echo -e "${GREEN}✅ 文件清理完成${NC}"
echo ""

# 5. 显示将要发布的文件
echo -e "${BLUE}📁 将要发布的文件：${NC}"
git ls-files | head -30
echo ""

# 6. 提交更改
echo -e "${BLUE}💾 提交更改...${NC}"
git add -A
git commit -m "Release ${VERSION} - GitHub 公开版本

仅包含：
- README.md
- LICENSE
- Package.swift
- Sources/NetworkMonitor/（核心代码）
- Sources/Examples/（示例代码）
" || echo "没有需要提交的更改"

# 7. 推送到 GitHub
echo ""
echo -e "${BLUE}🚀 推送到 GitHub...${NC}"
git push -f github ${TEMP_BRANCH}:main

# 8. 推送 tags
echo ""
echo -e "${BLUE}🏷️  推送 tags...${NC}"
git push github --tags

# 9. 切换回原分支并删除临时分支
echo ""
echo -e "${BLUE}🔄 清理临时分支...${NC}"
git checkout main
git branch -D ${TEMP_BRANCH}

echo ""
echo -e "${GREEN}✅ 发布完成！${NC}"
echo ""
echo -e "${BLUE}📍 GitHub 仓库地址：${NC}"
echo "   https://github.com/bigapuyo98-crypto/XFENetworkMonitor"
echo ""
echo -e "${BLUE}📦 SPM 集成方式：${NC}"
echo '   .package(url: "https://github.com/bigapuyo98-crypto/XFENetworkMonitor.git", from: "'${VERSION}'")'
echo ""

