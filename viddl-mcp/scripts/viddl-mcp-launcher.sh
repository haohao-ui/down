#!/usr/bin/env bash
# MCP 启动入口：确保二进制存在后 exec，stdout 保留给 MCP stdio 协议。
set -euo pipefail
bin="$("$(dirname "$0")/ensure-viddl-mcp.sh")"
exec "$bin" "$@"
