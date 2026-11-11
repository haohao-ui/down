#!/usr/bin/env bash
# 确保 viddl-mcp 二进制可用：已安装则输出路径，未安装则从 GitHub Releases 下载到 ~/.viddl-mcp/bin。
# 所有日志写 stderr，stdout 只输出二进制路径（--hook 模式下输出给 Claude 的提示）。
# 用法：ensure-viddl-mcp.sh [--hook]
set -euo pipefail

REPO="haohao-ui/down"
INSTALL_DIR="${VIDDL_MCP_HOME:-$HOME/.viddl-mcp}/bin"
LOCAL_BIN="$INSTALL_DIR/viddl-mcp"
HOOK_MODE=0
[ "${1:-}" = "--hook" ] && HOOK_MODE=1

log() { echo "[viddl] $*" >&2; }

find_bin() {
  if [ -n "${VIDDL_MCP_BIN:-}" ] && [ -x "$VIDDL_MCP_BIN" ]; then
    echo "$VIDDL_MCP_BIN"
  elif [ -x "$LOCAL_BIN" ]; then
    echo "$LOCAL_BIN"
  elif command -v viddl-mcp >/dev/null 2>&1; then
    command -v viddl-mcp
  else
    return 1
  fi
}

asset_name() {
  case "$(uname -s)/$(uname -m)" in
    Linux/x86_64) echo "viddl-mcp-linux-x86_64.tar.gz" ;;
    Darwin/arm64) echo "viddl-mcp-macos-aarch64.tar.gz" ;;
    Darwin/x86_64) echo "viddl-mcp-macos-x86_64.tar.gz" ;;
    *) return 1 ;;
  esac
}

# 发布仓库存放多个项目，tag 以项目名为前缀：viddl-mcp-vX.Y.Z 为固定版本，viddl-mcp-latest 始终指向最新版
download_asset() {
  local asset="$1" version="$2" dir="$3" tag base
  tag="viddl-mcp-${version:-latest}"
  base="https://github.com/$REPO/releases/download/$tag/$asset"
  local curl_opts=(--proto '=https' --tlsv1.2 --retry 3 --connect-timeout 15 --max-time 600 -fsSL)
  curl "${curl_opts[@]}" "$base" -o "$dir/$asset" || return 1
  # 供应链完整性：必须同时下载并校验 .sha256，失败即中止。
  curl "${curl_opts[@]}" "$base.sha256" -o "$dir/$asset.sha256" || {
    log "无法下载校验文件: $base.sha256"
    return 1
  }
  [ -s "$dir/$asset.sha256" ] || {
    log "校验文件为空: $base.sha256"
    return 1
  }
  (
    cd "$dir"
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum -c "$asset.sha256"
    elif command -v shasum >/dev/null 2>&1; then
      shasum -a 256 -c "$asset.sha256"
    else
      log "未找到 sha256sum/shasum，无法校验下载完整性"
      exit 1
    fi
  ) || {
    log "SHA-256 校验失败: $asset"
    return 1
  }
}

install_bin() {
  local asset version tmp
  if ! asset="$(asset_name)"; then
    log "暂不支持的平台: $(uname -s)/$(uname -m)，请从源码编译: cargo build --release"
    return 1
  fi

  version="${VIDDL_MCP_VERSION:-}"
  tmp="$(mktemp -d)"
  log "正在下载 viddl-mcp ${version:-latest} ($asset) ..."
  if download_asset "$asset" "$version" "$tmp" \
    && tar -xzf "$tmp/$asset" -C "$tmp" \
    && mkdir -p "$INSTALL_DIR" \
    && mv "$tmp/viddl-mcp" "$LOCAL_BIN" \
    && chmod +x "$LOCAL_BIN"; then
    rm -rf "$tmp"
    log "已安装到 $LOCAL_BIN"
  else
    rm -rf "$tmp"
    log "下载或解压失败: ${version:-latest}/$asset"
    return 1
  fi
}

# hook 与 MCP 启动可能同时触发安装，用目录锁串行化
LOCK_DIR="$INSTALL_DIR.lock"
with_lock() {
  local waited=0
  mkdir -p "$(dirname "$LOCK_DIR")"
  until mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 1
    waited=$((waited + 1))
    # 超时视为残留锁
    if [ "$waited" -ge 120 ]; then rm -rf "$LOCK_DIR"; fi
  done
  trap 'rm -rf "$LOCK_DIR"' EXIT
  "$@"
}

ensure() {
  find_bin >/dev/null 2>&1 || install_bin
}

if bin="$(find_bin)"; then
  installed_now=0
else
  with_lock ensure || {
    [ "$HOOK_MODE" = 1 ] && echo "viddl-mcp 未安装且自动安装失败，请手动运行: curl -fsSL https://raw.githubusercontent.com/$REPO/main/viddl-mcp/install.sh | bash"
    # hook 失败不阻断会话
    [ "$HOOK_MODE" = 1 ] && exit 0
    exit 1
  }
  bin="$(find_bin)"
  installed_now=1
fi

if [ "$HOOK_MODE" = 1 ]; then
  [ "$installed_now" = 1 ] && echo "viddl-mcp 已自动安装到 ${bin}。若 viddl MCP 工具未出现，请执行 /mcp 重连。"
  exit 0
fi
echo "$bin"
