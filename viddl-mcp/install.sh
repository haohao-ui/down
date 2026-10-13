#!/usr/bin/env bash
set -e

# viddl-mcp 一键安装脚本
# 二进制发布在公开仓库 haohao-ui/down（多项目共用，tag 带项目名前缀）
REPO="haohao-ui/down"
PROJECT="viddl-mcp"
INSTALL_DIR="/usr/local/bin"
FALLBACK_INSTALL_DIR="$HOME/.local/bin"

echo "📦 正在检测系统架构..."

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64)
        ASSET_NAME="viddl-mcp-linux-x86_64.tar.gz"
        ;;
      *)
        echo "❌ 暂不支持的 Linux 架构: $ARCH"
        exit 1
        ;;
    esac
    ;;
  Darwin)
    case "$ARCH" in
      arm64)
        ASSET_NAME="viddl-mcp-macos-aarch64.tar.gz"
        ;;
      x86_64)
        ASSET_NAME="viddl-mcp-macos-x86_64.tar.gz"
        ;;
      *)
        echo "❌ 暂不支持的 macOS 架构: $ARCH"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "❌ 暂不支持的操作系统: $OS"
    exit 1
    ;;
esac

echo "✅ 系统检测完成: $OS / $ARCH ($ASSET_NAME)"

# VERSION 为空时使用滚动 tag viddl-mcp-latest
TAG="$PROJECT-${VERSION:-latest}"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ASSET_NAME"
echo "📥 正在从 GitHub 下载 $TAG: $DOWNLOAD_URL ..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/$ASSET_NAME"

echo "📂 正在解压..."
tar -xzf "$TMP_DIR/$ASSET_NAME" -C "$TMP_DIR"

# 确定安装路径
TARGET_BIN="$INSTALL_DIR/viddl-mcp"
if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP_DIR/viddl-mcp" "$TARGET_BIN"
else
  if command -v sudo >/dev/null 2>&1; then
    echo "🔑 请求 sudo 权限以安装到 $INSTALL_DIR ..."
    sudo mv "$TMP_DIR/viddl-mcp" "$TARGET_BIN"
  else
    mkdir -p "$FALLBACK_INSTALL_DIR"
    TARGET_BIN="$FALLBACK_INSTALL_DIR/viddl-mcp"
    mv "$TMP_DIR/viddl-mcp" "$TARGET_BIN"
    echo "⚠️ 无法写入 $INSTALL_DIR，已安装到 $FALLBACK_INSTALL_DIR"
    echo "👉 请确保将 $FALLBACK_INSTALL_DIR 添加到你的 PATH 环境变量中"
  fi
fi

chmod +x "$TARGET_BIN"

echo ""
echo "🎉 安装完成！当前版本: $($TARGET_BIN --help 2>&1 | head -n 1)"
echo ""
echo "💡 常用命令:"
echo "  1. 一键下载单个视频/图集:"
echo "     viddl-mcp \"https://www.kuaishou.com/f/X6pe7uEz4WVpXeW\""
echo "  2. 指定下载输出目录:"
echo "     viddl-mcp -o ~/Downloads/my_videos \"<分享链接>\""
echo "  3. 作为 MCP 服务运行（在 Cursor / Claude Desktop 等客户端配置调用）:"
echo "     viddl-mcp"
echo ""
