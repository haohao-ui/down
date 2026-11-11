---
name: viddl
description: 多平台视频/图集下载与博主分析（抖音、TikTok、小红书、YouTube、快手、视频号）。当用户贴出这些平台的作品链接、分享文本、账号主页或合集链接，并要求下载、无水印保存、批量下载、查看元数据、分析博主/频道或获取最新作品列表时使用。视频号下载需元宝 Cookie，短链元数据查询免凭证。也用于排查 viddl MCP 工具不可用、Cookie 失效、403/400002 风控、YouTube 缺少 yt-dlp/ffmpeg 等问题。
---

# viddl：多平台视频下载

通过 `viddl` MCP server 的工具完成下载与解析。工具名形如 `mcp__viddl__download`（插件安装时可能带插件前缀，按实际可用名称调用）。

## 工具选择

| 用户意图 | 工具 | 说明 |
|---|---|---|
| 下载一条或多条作品 | `download` | `url` 可直接塞整段分享文本或多条链接，一次调用全部下载；抖音要原画传 `quality: "original"`；视频号原画传 `quality: "original"` 会得到 HEVC |
| 只看标题/作者/数据，不下载 | `get_metadata` | 视频号短链免凭证可查 |
| 下载视频号单条视频 | `download` | 需先配置元宝 Cookie，否则报错并提示更新 `wechat.yuanbao_cookie` |
| 分析博主/频道、看最新作品 | `get_user_info` | `count` 控制作品条数，默认 10；视频号不支持，改用 `get_metadata` 取单条作品的作者昵称/头像 |
| 下载博主全部/前 N 条作品 | `download_user` | 异步任务，`limit` 控制条数；支持抖音、TikTok、快手 |
| 下载抖音合集 | `download_collection` | 异步任务，链接形如 `/collection/xxx` |
| 查询/取消批量任务 | `get_job_status` / `cancel_job` | 参数 `job_id` |
| 检查配置、Cookie、代理、输出目录 | `get_status` | 排障第一步 |

## 工作方式

- 用户给的链接原样传入，不要自己改写短链或剥离分享文本，工具会解析。
- 批量任务返回 `job_id` 后，用 `get_job_status` 跟进进度，完成后汇总成功/失败数量与保存目录；不要高频轮询。
- 完成后告诉用户文件保存位置（默认 `~/Downloads/viddl`，批量归档在 `{output_dir}/{平台}/UID{作者}_{昵称}_发布作品/`）。
- 小红书、YouTube、视频号暂不支持账号批量下载，改为让用户提供多条单条链接交给 `download`。

## 常见问题

- **工具不存在 / MCP 连接失败**：先确认二进制存在。Claude Code 插件内运行 `${CLAUDE_PLUGIN_ROOT}/scripts/ensure-viddl-mcp.sh`；macOS / Linux 运行 `curl -fsSL https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/install.sh | bash`；Windows 运行 `irm https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/install.ps1 | iex`（脚本会自动将安装路径加入系统/用户 PATH 环境变量）。确认 MCP 配置里的 `command` 指向绝对路径或已生效的 `viddl-mcp` 命令后，重启或重连 MCP（Claude Code 为 `/mcp`）。完整安装说明见 https://raw.githubusercontent.com/haohao-ui/down/main/viddl-mcp/AGENT_INSTALL.md
- **403 或快手 400002（滑块风控）**：匿名模式受限。让用户在 `~/.config/viddl-mcp/config.toml` 对应平台下填写 `cookie`（浏览器登录后从 DevTools → Network 复制请求头 `Cookie`），快手也可用环境变量 `VIDDL_COOKIE_KUAISHOU`。改完需 `/mcp` 重连。
- **视频号提示“元宝登录态无效或已过期”**：元宝 Cookie 过期。让用户在 `~/.config/viddl-mcp/config.toml` 的 `[wechat] yuanbao_cookie` 更新，或用环境变量 `VIDDL_COOKIE_YUANBAO`；获取方式见 README 视频号章节。改完需 `/mcp` 重连。
- **TikTok / YouTube 访问失败**：需要代理，在配置 `[tiktok] proxy` / `[youtube] proxy` 填写，如 `http://127.0.0.1:7890`。
- **YouTube 提示缺少依赖**：`brew install yt-dlp ffmpeg`。
- **改下载目录**：配置文件里设置 `output_dir`。配置模板见仓库 `config.example.toml`。
