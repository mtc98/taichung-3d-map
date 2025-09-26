#!/bin/bash

# 台中景點3D地圖 - GitHub 自動部署腳本
# 作者: Thomas Mei (mtc98tw@gmail.com)
# github name : mtc98
# 使用方法: ./deploy_github.sh [repository_name]

set -e  # 遇到錯誤就停止

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：輸出彩色訊息
print_status() {
    echo -e "${BLUE}🚀 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 檢查參數
REPO_NAME=${1:-"taichung-3d-map"}
GITHUB_USERNAME="mtc98"  # 您的 GitHub 用戶名
REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

print_status "開始部署台中景點3D地圖到 GitHub..."
echo "Repository: ${REPO_URL}"
echo "=================================="

# 檢查是否為 Git repository
if [ ! -d ".git" ]; then
    print_error "這不是一個 Git repository！"
    print_status "正在初始化 Git..."
    git init
    git config user.email "mtc98tw@gmail.com"
    git config user.name "mtc98"
    git branch -M main
    print_success "Git 初始化完成"
fi

# 檢查是否有 remote origin
if ! git remote get-url origin >/dev/null 2>&1; then
    print_status "添加 GitHub remote..."
    git remote add origin ${REPO_URL}
    print_success "Remote 添加完成"
else
    print_warning "Remote origin 已存在，跳過添加"
fi

# 提交目前變更
if ! git diff --quiet || ! git diff --cached --quiet; then
    print_status "提交目前變更..."
    git add .
    COMMIT_MSG="update: $(date '+%Y-%m-%d %H:%M:%S') 自動部署更新"
    git commit -m "${COMMIT_MSG}"
    print_success "變更已提交"
else
    print_warning "沒有變更需要提交"
fi

# 推送主分支
print_status "推送主分支到 GitHub..."
if git push origin main; then
    print_success "主分支推送成功"
else
    print_warning "主分支推送失敗，可能需要設定 GitHub 認證"
    echo "請執行: git push -u origin main"
fi

# 建立 Web 版本
print_status "建立 Flutter Web 版本..."
if flutter build web --release; then
    print_success "Web 版本建立成功"
else
    print_error "Web 版本建立失敗！"
    exit 1
fi

# 部署到 GitHub Pages
print_status "準備 GitHub Pages 部署..."

# 使用 subtree 將 build/web 目錄的內容推送到 gh-pages 分支
# 這個方法更乾淨且安全，不會動到目前的工作目錄
print_status "正在將 build/web 目錄部署到 gh-pages 分支..."
if git subtree push --prefix build/web origin gh-pages; then
    print_success "GitHub Pages 部署成功"
else
    print_error "GitHub Pages 部署失敗！"
    print_warning "請確認 'build/web' 目錄存在，或嘗試手動執行以下指令："
    print_warning "git subtree push --prefix build/web origin gh-pages"
    exit 1
fi

# 因為未使用 checkout，所以不需要切回 main 分支
# print_status "切回主分支..."
# git checkout main

# 完成提示
echo "=================================="
print_success "部署完成！"
echo ""
print_status "接下來的步驟："
echo "1. 前往 GitHub 建立 Repository (如果還沒建立):"
echo "   ${REPO_URL}"
echo ""
echo "2. 在 Repository 中啟用 GitHub Pages:"
echo "   Settings → Pages → Source: Deploy from branch → gh-pages"
echo ""
echo "3. 等待 2-3 分鐘後即可訪問："
echo "   https://${GITHUB_USERNAME}.github.io/${REPO_NAME}"
echo ""
print_warning "注意：如果推送失敗，可能需要設定 GitHub 個人存取權杖 (Personal Access Token)"
echo "設定方法: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token"