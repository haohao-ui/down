#!/usr/bin/env bash
set -euo pipefail

# viddl-mcp 一键安装脚本
# 二进制发布在公开仓库 haohao-ui/down（多项目共用，tag 带项目名前缀）
REPO="haohao-ui/down"
PROJECT="viddl-mcp"
INSTALL_DIR="/usr/local/bin"
FALLBACK_INSTALL_DIR="$HOME/.local/bin"

# 固定版本：VIDDL_MCP_VERSION=v0.1.3（兼容旧变量 VERSION）；留空安装滚动 latest。
VERSION="${VIDDL_MCP_VERSION:-${VERSION:-}}"

die() {
  echo "❌ $*" >&2
  exit 1
}

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
        die "暂不支持的 Linux 架构: $ARCH"
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
        die "暂不支持的 macOS 架构: $ARCH"
        ;;
    esac
    ;;
  *)
    die "暂不支持的操作系统: $OS"
    ;;
esac

echo "✅ 系统检测完成: $OS / $ARCH ($ASSET_NAME)"

TAG="$PROJECT-${VERSION:-latest}"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ASSET_NAME"
SHA_URL="$DOWNLOAD_URL.sha256"
echo "📥 正在从 GitHub 下载 $TAG: $DOWNLOAD_URL ..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CURL_OPTS=(--proto '=https' --tlsv1.2 --retry 3 --connect-timeout 15 --max-time 600 -fsSL)

curl "${CURL_OPTS[@]}" "$DOWNLOAD_URL" -o "$TMP_DIR/$ASSET_NAME"
# 供应链完整性：必须同时拿到发布侧生成的 .sha256 并校验通过，否则拒绝安装。
curl "${CURL_OPTS[@]}" "$SHA_URL" -o "$TMP_DIR/$ASSET_NAME.sha256"
[ -s "$TMP_DIR/$ASSET_NAME.sha256" ] || die "校验文件为空: $SHA_URL"

echo "🔐 正在校验下载包 SHA-256 ..."
(
  cd "$TMP_DIR"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$ASSET_NAME.sha256"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$ASSET_NAME.sha256"
  else
    die "未找到 sha256sum/shasum，无法校验下载完整性"
  fi
)

echo "📂 正在解压..."
tar -xzf "$TMP_DIR/$ASSET_NAME" -C "$TMP_DIR"

# 确定安装路径：优先 /usr/local/bin，必要时才使用 sudo（一次性 install，避免 sudo mv 后普通用户 chmod 失败）
if [ -w "$INSTALL_DIR" ]; then
  TARGET_DIR="$INSTALL_DIR"
  TARGET_BIN="$TARGET_DIR/viddl-mcp"
  install -m 755 "$TMP_DIR/viddl-mcp" "$TARGET_BIN"
else
  if command -v sudo >/dev/null 2>&1; then
    echo "🔑 请求 sudo 权限以安装到 $INSTALL_DIR ..."
    TARGET_DIR="$INSTALL_DIR"
    TARGET_BIN="$TARGET_DIR/viddl-mcp"
    sudo install -m 755 "$TMP_DIR/viddl-mcp" "$TARGET_BIN"
  else
    mkdir -p "$FALLBACK_INSTALL_DIR"
    TARGET_DIR="$FALLBACK_INSTALL_DIR"
    TARGET_BIN="$TARGET_DIR/viddl-mcp"
    install -m 755 "$TMP_DIR/viddl-mcp" "$TARGET_BIN"
    echo "⚠️ 无法写入 $INSTALL_DIR，已安装到 $TARGET_DIR"
  fi
fi

# 自动检测并配置 PATH 环境变量
configure_path() {
  local target_dir="$1"

  # 检查当前 PATH 是否已包含该目录
  case ":$PATH:" in
    *":$target_dir:"*)
      return 0
      ;;
  esac

  echo ""
  echo "⚙️ 检测到 $target_dir 不在当前系统 PATH 中，正在配置环境变量..."

  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"
  local rc_file=""

  case "$shell_name" in
    zsh)
      rc_file="$HOME/.zshrc"
      ;;
    bash)
      if [ "$OS" = "Darwin" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
          rc_file="$HOME/.bash_profile"
        elif [ -f "$HOME/.bashrc" ]; then
          rc_file="$HOME/.bashrc"
        else
          rc_file="$HOME/.bash_profile"
        fi
      else
        rc_file="$HOME/.bashrc"
      fi
      ;;
    fish)
      rc_file="$HOME/.config/fish/config.fish"
      ;;
    *)
      if [ -f "$HOME/.profile" ]; then
        rc_file="$HOME/.profile"
      elif [ -f "$HOME/.bashrc" ]; then
        rc_file="$HOME/.bashrc"
      else
        rc_file="$HOME/.profile"
      fi
      ;;
  esac

  if [ -n "$rc_file" ]; then
    if [ -f "$rc_file" ] && grep -F "$target_dir" "$rc_file" >/dev/null 2>&1; then
      echo "ℹ️ $rc_file 中已包含 $target_dir"
    else
      mkdir -p "$(dirname "$rc_file")"
      if [ "$shell_name" = "fish" ]; then
        {
          echo ""
          echo "# viddl-mcp PATH"
          echo "fish_add_path $target_dir"
        } >> "$rc_file"
      else
        {
          echo ""
          echo "# viddl-mcp PATH"
          echo "export PATH=\"$target_dir:\$PATH\""
        } >> "$rc_file"
      fi
      echo "✅ 已自动将 $target_dir 添加到 $rc_file"
      echo "👉 请执行以下命令使其在当前终端立即生效："
      echo "   source $rc_file"
    fi
  else
    echo "⚠️ 未能识别 shell 配置文件，请手动将以下内容添加到你的配置文件中："
    echo "   export PATH=\"$target_dir:\$PATH\""
  fi
}

configure_path "$TARGET_DIR"

echo ""
echo "🎉 安装完成！当前版本: $("$TARGET_BIN" --help 2>&1 | head -n 1)"
echo ""
echo "💡 常用命令:"
echo "  1. 一键下载单个视频/图集:"
echo "     viddl-mcp \"https://www.kuaishou.com/f/X6pe7uEz4WVpXeW\""
echo "  2. 指定下载输出目录:"
echo "     viddl-mcp -o ~/Downloads/my_videos \"<分享链接>\""
echo "  3. 作为 MCP 服务运行（在 Cursor / Claude Desktop 等客户端配置调用）:"
echo "     viddl-mcp"
echo ""
