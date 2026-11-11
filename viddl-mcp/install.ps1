# viddl-mcp Windows 一键安装脚本
# 支持通过 PowerShell 运行: irm https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/install.ps1 | iex
# 固定版本：install.ps1 -Version v0.1.3（须与 GitHub Release tag 一致，可省略前导 v）

param (
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$Repo = "haohao-ui/down"
$Project = "viddl-mcp"
$InstallDir = "$env:USERPROFILE\.viddl-mcp\bin"
$TargetBin = "$InstallDir\viddl-mcp.exe"

Write-Host "📦 正在准备安装 viddl-mcp (Windows x86_64)..."

# 确定下载版本 tag（固定版本可写 v0.1.3 或 0.1.3）
$Tag = if ($Version) {
    $Normalized = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
    "$Project-$Normalized"
} else { "$Project-latest" }
$Asset = "viddl-mcp-windows-x86_64.zip"
$DownloadUrl = "https://github.com/$Repo/releases/download/$Tag/$Asset"

$TempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    $ZipPath = Join-Path $TempDir $Asset
    Write-Host "📥 正在从 GitHub 下载 $Tag : $DownloadUrl ..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing

    # 供应链完整性：必须校验发布侧生成的 .sha256，失败即中止。
    $ShaUrl = "$DownloadUrl.sha256"
    $ShaPath = Join-Path $TempDir "$Asset.sha256"
    try {
        Invoke-WebRequest -Uri $ShaUrl -OutFile $ShaPath -UseBasicParsing
    } catch {
        throw "无法下载校验文件 $ShaUrl，已中止安装（可用 -Version 指定含校验文件的版本）"
    }
    $Expected = ((Get-Content -Path $ShaPath -Raw) -split '\s+')[0].Trim()
    if (-not $Expected) { throw "校验文件为空: $ShaUrl" }
    $Actual = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash
    if ($Actual -ne $Expected.ToUpperInvariant()) {
        throw "SHA-256 校验失败：下载包与发布校验值不一致，已中止安装"
    }
    Write-Host "🔐 下载包 SHA-256 校验通过"

    Write-Host "📂 正在解压..."
    $ExtractDir = Join-Path $TempDir "extracted"
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path (Join-Path $ExtractDir "viddl-mcp.exe") -Destination $TargetBin -Force
    Write-Host "✅ 二进制已安装至: $TargetBin"
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 自动配置 Windows 用户环境变量 PATH
Write-Host "⚙️ 正在检查系统 PATH 环境变量..."
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $UserPath) {
    $UserPath = ""
}

$PathList = $UserPath -split ';' | Where-Object { $_ -ne "" }
if ($PathList -notcontains $InstallDir) {
    $NewUserPath = if ($UserPath.Length -gt 0) { "$UserPath;$InstallDir" } else { $InstallDir }
    # 保留用户 PATH 原有注册表类型（REG_EXPAND_SZ 不能被写成 REG_SZ，否则 %VAR% 将不再展开）。
    $EnvKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    if ($EnvKey) {
        $PathKind = [Microsoft.Win32.RegistryValueKind]::ExpandString
        try { $PathKind = $EnvKey.GetValueKind('Path') } catch { }
        $EnvKey.SetValue('Path', $NewUserPath, $PathKind)
        $EnvKey.Close()
    } else {
        [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
    }
    Write-Host "✅ 已将 $InstallDir 永久添加到用户 PATH 环境变量"
} else {
    Write-Host "ℹ️ 用户 PATH 环境变量中已包含 $InstallDir"
}

# 同步刷新当前 PowerShell 会话 PATH
if (($env:Path -split ';') -notcontains $InstallDir) {
    $env:Path = "$InstallDir;$env:Path"
}

Write-Host ""
try {
    $VerInfo = & "$TargetBin" --help 2>&1 | Select-Object -First 1
    Write-Host "🎉 安装完成！当前版本: $VerInfo"
} catch {
    Write-Host "🎉 安装完成！"
}

Write-Host ""
Write-Host "💡 常用命令:"
Write-Host "  1. 一键下载单个视频/图集:"
Write-Host "     viddl-mcp `"https://www.kuaishou.com/f/X6pe7uEz4WVpXeW`""
Write-Host "  2. 指定下载输出目录:"
Write-Host "     viddl-mcp -o `"`$HOME\Downloads\my_videos`" `"<分享链接>`""
Write-Host "  3. 作为 MCP 服务运行（在 Cursor / Claude Desktop 等客户端配置调用）:"
Write-Host "     viddl-mcp"
Write-Host ""
