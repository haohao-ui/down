# viddl-mcp

多平台视频/图集下载 MCP 工具（抖音 / TikTok / 小红书 / YouTube / 快手）：无水印下载、账号/合集批量下载、博主画像。

## Claude Code 插件（推荐）

```
/plugin marketplace add haohao-ui/down
/plugin install viddl@down
```

一并安装 MCP server 与使用指南 Skill。首次启动会自动下载对应平台的二进制到 `~/.viddl-mcp/bin`（PATH 中已有则直接复用）。

- `VIDDL_MCP_VERSION=v0.1.0`：固定版本（默认最新）
- `VIDDL_MCP_BIN=/path/to/viddl-mcp`：使用已有二进制

## 命令行安装（macOS / Linux）

```bash
curl -fsSL https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/install.sh | bash
```

安装后可直接命令行下载：

```bash
viddl-mcp "<分享链接>"
viddl-mcp -o ~/Desktop/videos -q original "<抖音分享链接>"
```

Windows 请到 [Releases](https://github.com/haohao-ui/down/releases?q=viddl-mcp) 下载 `viddl-mcp-windows-x86_64.zip`。

## 手动配置 MCP

```json
{
  "mcpServers": {
    "viddl": { "command": "viddl-mcp" }
  }
}
```

## 配置

`~/.config/viddl-mcp/config.toml`（模板见发布包内 `config.example.toml`）：

- `output_dir`：下载目录（默认 `~/Downloads/viddl`）
- `[douyin] cookie` / `[kuaishou] cookie` 等：匿名模式受风控（403 / 400002）时填写浏览器登录后的 Cookie
- `[tiktok] proxy` / `[youtube] proxy`：代理，如 `http://127.0.0.1:7890`
- YouTube 需要 `yt-dlp` 与 `ffmpeg`：`brew install yt-dlp ffmpeg`
