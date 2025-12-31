# =========================================
# Hugo 博客一键发布脚本（深度清理版）
# =========================================

param(
    [string]$PostTitle,
    [string]$ProjectDir = "D:\software\Hugo\Twojian",
    [string]$GitHubUsername = "twojian",
    [string]$Editor = "code"
)

# 初始化编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($PostTitle)) {
    Write-Host "`n❌ 错误：请提供文章标题！" -ForegroundColor Red
    exit
}

Set-Location $ProjectDir

# --------------------------
# 1. 创建文章 (支持 Page Bundle 模式)
# --------------------------
# 建议使用文件夹模式(index.md)，这样图片可以直接放一起
$Slug = $PostTitle -replace ' ', '-' -replace '[^a-zA-Z0-9\u4e00-\u9fa5\-]', ''
$PostPath = "content/posts/$Slug/index.md"

Write-Host "🚀 正在创建文章 (Page Bundle)..." -ForegroundColor Cyan
hugo new $PostPath

# --------------------------
# 2. 编辑文章
# --------------------------
Write-Host "⌨️  正在打开编辑器..." -ForegroundColor Yellow
Start-Process $Editor (Join-Path $ProjectDir $PostPath) -Wait
Read-Host "确认文件已保存？按【回车键】开始深度清理并生成..."

# --------------------------
# 3. 深度清理与重新编译 (解决图标过大的核心步骤)
# --------------------------
Write-Host "🧹 正在清理旧的静态文件与缓存..." -ForegroundColor Yellow
# 物理删除 public 和 resources，确保样式 100% 重新生成
if (Test-Path "public") { Remove-Item -Path "public" -Recurse -Force }
if (Test-Path "resources") { Remove-Item -Path "resources" -Recurse -Force }

Write-Host "🏗️  正在生成静态页面 (Production Mode)..." -ForegroundColor Cyan
# 不加 -D 确保草稿不会被发布，--gc 进一步清理残留
hugo --gc --minify

$PublicDir = Join-Path $ProjectDir "public"

# --------------------------
# 4. 部署到 GitHub (HTTPS 模式)
# --------------------------
Set-Location $PublicDir

# 确保 Git 初始化
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

# 自动处理 Remote 
# 注意：若之前推送失败，建议手动运行一次 git remote set-url origin https://github.com/twojian/twojian.github.io.git
$RemoteURL = "https://github.com/$GitHubUsername/$GitHubUsername.github.io.git"
git remote add origin $RemoteURL 2>$null
git remote set-url origin $RemoteURL

# 提交并强制推送
git add .
$CommitMsg = "Publish: $PostTitle $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git commit -m $CommitMsg

Write-Host "📤 正在强力推送至 GitHub..." -ForegroundColor Cyan
git push -u origin main --force

Write-Host "`n✨ 部署成功！" -ForegroundColor Green
Write-Host "提示：若图标没变，请在浏览器按 Ctrl+F5 刷新。" -ForegroundColor Gray

Set-Location $ProjectDir