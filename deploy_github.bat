@echo off
REM 台中景點3D地圖 - GitHub 自動部署腳本 (Windows版)
REM 作者: Thomas Mei (mtc98tw@gmail.com)
REM 使用方法: deploy_github.bat [repository_name]

setlocal enabledelayedexpansion

REM 設定變數
if "%~1"=="" (
    set REPO_NAME=taichung-3d-map
) else (
    set REPO_NAME=%~1
)
set GITHUB_USERNAME=mtc98tw
set REPO_URL=https://github.com/!GITHUB_USERNAME!/!REPO_NAME!.git

echo.
echo ========================================
echo 🚀 台中景點3D地圖 - GitHub 自動部署
echo ========================================
echo Repository: !REPO_URL!
echo.

REM 檢查是否為 Git repository
if not exist ".git" (
    echo ❌ 這不是一個 Git repository！
    echo 🔧 正在初始化 Git...
    git init
    git config user.email "mtc98tw@gmail.com"
    git config user.name "mtc98tw"
    git branch -M main
    echo ✅ Git 初始化完成
)

REM 檢查並添加 remote
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo 🔧 添加 GitHub remote...
    git remote add origin !REPO_URL!
    echo ✅ Remote 添加完成
) else (
    echo ⚠️  Remote origin 已存在，跳過添加
)

REM 提交目前變更
git diff --quiet && git diff --cached --quiet
if errorlevel 1 (
    echo 🔧 提交目前變更...
    git add .
    for /f "tokens=1-3 delims=/ " %%i in ('date /t') do set mydate=%%k-%%i-%%j
    for /f "tokens=1-2 delims=: " %%i in ('time /t') do set mytime=%%i:%%j
    git commit -m "update: !mydate! !mytime! 自動部署更新"
    echo ✅ 變更已提交
) else (
    echo ⚠️  沒有變更需要提交
)

REM 推送主分支
echo 🔧 推送主分支到 GitHub...
git push origin main
if errorlevel 1 (
    echo ⚠️  主分支推送失敗，可能需要設定 GitHub 認證
    echo 請執行: git push -u origin main
) else (
    echo ✅ 主分支推送成功
)

REM 建立 Web 版本
echo 🔧 建立 Flutter Web 版本...
flutter build web --release
if errorlevel 1 (
    echo ❌ Web 版本建立失敗！
    pause
    exit /b 1
)
echo ✅ Web 版本建立成功

REM 處理 GitHub Pages
echo 🔧 準備 GitHub Pages 部署...

REM 檢查是否存在 gh-pages 分支
git show-ref --verify --quiet refs/heads/gh-pages
if errorlevel 1 (
    echo 🔧 建立新的 gh-pages 分支...
    git checkout -b gh-pages
) else (
    echo 🔧 切換到現有的 gh-pages 分支...
    git checkout gh-pages
    
    REM 清除舊檔案 (Windows版本 - 安全方式)
    echo 🔧 清除舊的部署檔案...
    if exist assets rmdir /s /q assets 2>nul
    if exist canvaskit rmdir /s /q canvaskit 2>nul
    if exist icons rmdir /s /q icons 2>nul
    del *.html *.js *.json *.wasm *.png 2>nul
)

REM 複製 Web 檔案
echo 🔧 複製 Web 檔案到部署分支...
xcopy "build\web\*" "." /s /e /y /q

REM 提交 GitHub Pages
echo 🔧 提交 GitHub Pages 檔案...
git add .
for /f "tokens=1-3 delims=/ " %%i in ('date /t') do set mydate=%%k-%%i-%%j
for /f "tokens=1-2 delims=: " %%i in ('time /t') do set mytime=%%i:%%j
git commit -m "deploy: !mydate! !mytime! GitHub Pages 自動部署"

REM 推送 GitHub Pages
echo 🔧 推送 GitHub Pages...
git push origin gh-pages
if errorlevel 1 (
    echo ⚠️  GitHub Pages 推送失敗，可能需要設定 GitHub 認證
    echo 請執行: git push origin gh-pages
) else (
    echo ✅ GitHub Pages 部署成功
)

REM 切回主分支
echo 🔧 切回主分支...
git checkout main

REM 完成提示
echo.
echo ========================================
echo ✅ 部署完成！
echo ========================================
echo.
echo 📋 接下來的步驟：
echo 1. 前往 GitHub 建立 Repository (如果還沒建立):
echo    !REPO_URL!
echo.
echo 2. 在 Repository 中啟用 GitHub Pages:
echo    Settings → Pages → Source: Deploy from branch → gh-pages
echo.
echo 3. 等待 2-3 分鐘後即可訪問：
echo    https://!GITHUB_USERNAME!.github.io/!REPO_NAME!
echo.
echo ⚠️  注意：如果推送失敗，可能需要設定 GitHub 個人存取權杖
echo    設定方法: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
echo.
pause