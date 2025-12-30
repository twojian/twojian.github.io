# =========================================
# Hugo + PaperMod 自动部署脚本 (Windows)
# =========================================

# --------------------------
# 配置参数
# --------------------------
$ProjectDir = "D:\software\Hugo\Twojian"      # Hugo 项目根目录
$RepoURL_HTTPS = "https://github.com/twojian/twojian.github.io.git"
$RepoURL_SSH   = "git@github.com:twojian/twojian.github.io.git"
$DeployMethod = "HTTPS"                        # "HTTPS" 或 "SSH"
$GitHubPAT = "ghp_XXXXXXXXXXXXXXXXXXXX"       # HTTPS 使用的 Personal Access Token

# --------------------------
# 切换到项目目录
# --------------------------
if (-not (Test-Path $ProjectDir)) {
    Write-Host "❌ 项目目录不存在: $ProjectDir"
    exit
}
Set-Location $ProjectDir
Write-Host "✅ 切换到项目目录: $ProjectDir"

# --------------------------
# 更新 config.yaml baseURL
# --------------------------
$configFile = Join-Path $ProjectDir "config.yaml"
if (Test-Path $configFile) {
    $baseURL = "https://twojian.github.io/"
    (Get-Content $configFile) -replace '^baseURL:.*$', "baseURL: `"$baseURL`"" | Set-Content $configFile
    Write-Host "✅ baseURL 已更新为 $baseURL"
} else {
    Write-Host "❌ 配置文件不存在: config.yaml"
    exit
}

# --------------------------
# 生成静态文件到 public/
# --------------------------
hugo -D -d public

$PublicDir = Join-Path $ProjectDir "public"
if (-not (Test-Path $PublicDir)) {
    Write-Host "❌ Hugo 生成失败: public/ 不存在"
    exit
}
Write-Host "✅ Hugo 静态文件生成完成"

# --------------------------
# 切换到 public/
# --------------------------
Set-Location $PublicDir

# --------------------------
# 初始化 Git（如果未初始化）
# --------------------------
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
    Write-Host "✅ 初始化 Git 仓库"
}

# --------------------------
# 配置 remote
# --------------------------
$CurrentOrigin = git remote get-url origin 2>$null
if ($CurrentOrigin) {
    Write-Host "⚠️ 远程 origin 已存在，更新 URL"
    if ($DeployMethod -eq "HTTPS") {
        git remote set-url origin "https://$($env:USERNAME):$GitHubPAT@github.com/twojian/twojian.github.io.git"
    } else {
        git remote set-url origin $RepoURL_SSH
    }
} else {
    Write-Host "✅ 添加远程仓库 origin"
    if ($DeployMethod -eq "HTTPS") {
        git remote add origin "https://$($env:USERNAME):$GitHubPAT@github.com/twojian/twojian.github.io.git"
    } else {
        git remote add origin $RepoURL_SSH
    }
}

# --------------------------
# 提交并推送
# --------------------------
git add .
git commit -m "Deploy Hugo site $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "⏳ 正在推送到 GitHub Pages..."
git push -u origin main --force

Write-Host "✅ 部署完成！访问: https://twojian.github.io/"
