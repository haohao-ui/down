# viddl-mcp 安装指南（给 AI Agent 阅读）

你正在为用户安装 **viddl-mcp**：一个多平台视频/图集下载 MCP server（抖音 / TikTok / 小红书 / YouTube / 快手）。按下面步骤执行，每一步都实际运行命令并检查结果，不要只给用户讲步骤。

## 第 0 步：确认你是哪个 Agent

根据你自己的身份选择第 2 步里对应的章节。无法确定时，询问用户正在使用哪个工具。修改任何已有配置文件前先读取它，**合并**新增的 `viddl` 条目，保留原有内容；不要覆盖整个文件。

## 第 1 步：安装二进制

二进制装到用户目录 `~/.viddl-mcp/bin`，不需要 sudo。已安装时会直接复用。

**macOS / Linux：**

```bash
curl -fsSL https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/scripts/ensure-viddl-mcp.sh | bash
```

脚本最后一行输出二进制**绝对路径**（如 `/Users/xxx/.viddl-mcp/bin/viddl-mcp`），记下它，下文用 `<BIN>` 表示。
支持 macOS（Apple Silicon / Intel）与 Linux x86_64。需要固定版本时在 `bash` 前加 `VIDDL_MCP_VERSION=v0.1.0`。

**Windows（PowerShell）：**

```powershell
$dir = "$env:USERPROFILE\.viddl-mcp\bin"
New-Item -ItemType Directory -Force $dir | Out-Null
$zip = "$env:TEMP\viddl-mcp.zip"
Invoke-WebRequest "https://github.com/haohao-ui/down/releases/download/viddl-mcp-latest/viddl-mcp-windows-x86_64.zip" -OutFile $zip
Expand-Archive $zip -DestinationPath "$env:TEMP\viddl-mcp" -Force
Copy-Item "$env:TEMP\viddl-mcp\viddl-mcp.exe" $dir -Force
Write-Output "$dir\viddl-mcp.exe"
```

输出的路径即 `<BIN>`。写入 JSON 时反斜杠需转义为 `\\`，或改用正斜杠 `/`。

**验证：** 运行 `<BIN> --help`，能输出帮助即成功。

> MCP 配置里一律使用 `<BIN>` 绝对路径，不要只写 `viddl-mcp`：桌面应用（Claude Desktop、Cursor 等）通常拿不到终端的 PATH。

## 第 2 步：注册 MCP server 与使用指南

使用指南（Skill）告诉 Agent 何时、如何调用这些工具。下载地址：

```
https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/skills/viddl/SKILL.md
```

“安装 Skill”指把它保存为 `<技能目录>/viddl/SKILL.md`。

### Claude Code

优先安装插件（MCP、Skill、二进制自动安装一次到位，无需第 1 步）：

```bash
claude plugin marketplace add haohao-ui/down
claude plugin install viddl@down
```

插件命令不可用时退回手动方式：

```bash
claude mcp add -s user viddl -- <BIN>
mkdir -p ~/.claude/skills/viddl
curl -fsSL https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/skills/viddl/SKILL.md -o ~/.claude/skills/viddl/SKILL.md
```

### Codex CLI

```bash
codex mcp add viddl -- <BIN>
mkdir -p ~/.codex/skills/viddl
curl -fsSL https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/skills/viddl/SKILL.md -o ~/.codex/skills/viddl/SKILL.md
```

（`codex mcp add` 不可用时，在 `~/.codex/config.toml` 追加 `[mcp_servers.viddl]` 与 `command = "<BIN>"`。）

### Gemini CLI

```bash
gemini mcp add -s user viddl <BIN>
mkdir -p ~/.gemini/skills/viddl
curl -fsSL https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/skills/viddl/SKILL.md -o ~/.gemini/skills/viddl/SKILL.md
```

### OpenCode

编辑 `~/.config/opencode/opencode.json`，在 `mcp` 下合并：

```json
{
  "mcp": {
    "viddl": { "type": "local", "command": ["<BIN>"], "enabled": true }
  }
}
```

Skill 保存到 `~/.config/opencode/skills/viddl/SKILL.md`。

### Cursor

编辑 `~/.cursor/mcp.json`（全局）或项目内 `.cursor/mcp.json`，在 `mcpServers` 下合并：

```json
{
  "mcpServers": {
    "viddl": { "command": "<BIN>" }
  }
}
```

如果当前 Cursor 版本支持 Agent Skills，把 Skill 放到其技能目录；不支持则跳过，MCP 工具自带说明可直接使用。

### Claude Desktop

编辑配置文件，在 `mcpServers` 下合并（同 Cursor 格式）：

- macOS：`~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows：`%APPDATA%\Claude\claude_desktop_config.json`

保存后需要用户**完全退出并重新打开** Claude Desktop。

### Windsurf

编辑 `~/.codeium/windsurf/mcp_config.json`，在 `mcpServers` 下合并（同 Cursor 格式）。

### VS Code（GitHub Copilot）

运行（注意 VS Code 使用 `servers` 键而非 `mcpServers`）：

```bash
code --add-mcp '{"name":"viddl","type":"stdio","command":"<BIN>"}'
```

或编辑工作区 `.vscode/mcp.json`：`{ "servers": { "viddl": { "type": "stdio", "command": "<BIN>" } } }`。

### 其他 Agent（Cline、Kiro、Trae、Cherry Studio 等）

viddl-mcp 是标准 stdio MCP server：命令为 `<BIN>`，无参数，无需环境变量。在该 Agent 的 MCP 配置中添加名为 `viddl` 的 server，大多数工具使用以下格式：

```json
{ "mcpServers": { "viddl": { "command": "<BIN>" } } }
```

找不到配置位置时，告诉用户在该工具的 MCP 设置界面手动添加，并给出上述命令。若该 Agent 支持 Agent Skills（`~/.agents/skills/` 等目录），一并安装 Skill。

## 第 3 步：可选配置

按用户需要处理，不需要时跳过：

- **配置文件** `~/.config/viddl-mcp/config.toml`（不存在则使用默认值）：
  - `output_dir = "~/Downloads/viddl"`：下载目录
  - `[douyin] cookie` / `[kuaishou] cookie` / `[xiaohongshu] cookie` / `[tiktok] cookie`：匿名访问被风控（403、快手 400002）时，填浏览器登录后请求头里的 Cookie
  - `[tiktok] proxy` / `[youtube] proxy`：如 `"http://127.0.0.1:7890"`，TikTok 必须配置代理
  - 完整模板：https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/config.example.toml（不可用时，发布包内也附带 `config.example.toml`）
- **YouTube** 需要 `yt-dlp` 与 `ffmpeg`：macOS `brew install yt-dlp ffmpeg`，Linux 用系统包管理器，Windows `winget install yt-dlp.yt-dlp` 与 `winget install Gyan.FFmpeg`。

## 第 4 步：验证并汇报

1. 提醒用户重启 Agent 或重连 MCP（Claude Code 执行 `/mcp`）使配置生效。
2. 生效后调用 `ping` 工具应返回 `pong`，`get_status` 可查看配置与 Cookie 状态。当前会话无法热加载时，说明重启后再验证即可。
3. 向用户汇报：二进制路径、修改了哪些配置文件、Skill 安装位置、还需要用户做什么（如重启）。
4. 给出用法示例：直接对 Agent 说“把这个视频下载下来 <分享链接>”或“分析一下这个博主 <主页链接>”。
