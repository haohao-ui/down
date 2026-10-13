---
name: viddl
description: 多平台视频/图集下载与博主分析（抖音、TikTok、小红书、YouTube、快手）。当用户贴出这些平台的作品链接、分享文本、账号主页或合集链接，并要求下载、无水印保存、批量下载、查看元数据、分析博主/频道或获取最新作品列表时使用。也用于排查 viddl MCP 工具不可用、Cookie 失效、403/400002 风控、YouTube 缺少 yt-dlp/ffmpeg 等问题。
---

# viddl：多平台视频下载

通过 `viddl` MCP server 的工具完成下载与解析。工具名形如 `mcp__viddl__download`（插件安装时可能带插件前缀，按实际可用名称调用）。

## 工具选择

| 用户意图 | 工具 | 说明 |
|---|---|---|
| 下载一条或多条作品 | `download` | `url` 可直接塞整段分享文本或多条链接，一次调用全部下载；抖音要原画传 `quality: "original"` |
| 只看标题/作者/数据，不下载 | `get_metadata` | |
| 分析博主/频道、看最新作品 | `get_user_info` | `count` 控制作品条数，默认 10 |
| 下载博主全部/前 N 条作品 | `download_user` | 异步任务，`limit` 控制条数；支持抖音、TikTok、快手 |
| 下载抖音合集 | `download_collection` | 异步任务，链接形如 `/collection/xxx` |
| 查询/取消批量任务 | `get_job_status` / `cancel_job` | 参数 `job_id` |
| 检查配置、Cookie、代理、输出目录 | `get_status` | 排障第一步 |

## 工作方式

- 用户给的链接原样传入，不要自己改写短链或剥离分享文本，工具会解析。
- 批量任务返回 `job_id` 后，用 `get_job_status` 跟进进度，完成后汇总成功/失败数量与保存目录；不要高频轮询。
- 完成后告诉用户文件保存位置（默认 `~/Downloads/viddl`，批量归档在 `{output_dir}/{平台}/UID{作者}_{昵称}_发布作品/`）。
- 小红书、YouTube 暂不支持账号批量下载，改为让用户提供多条单条链接交给 `download`。

## 常见问题

- **工具不存在 / MCP 连接失败**：运行 `${CLAUDE_PLUGIN_ROOT}/scripts/ensure-viddl-mcp.sh` 安装二进制（会输出安装路径），然后让用户执行 `/mcp` 重连 viddl。
- **403 或快手 400002（滑块风控）**：匿名模式受限。让用户在 `~/.config/viddl-mcp/config.toml` 对应平台下填写 `cookie`（浏览器登录后从 DevTools → Network 复制请求头 `Cookie`），快手也可用环境变量 `VIDDL_COOKIE_KUAISHOU`。改完需 `/mcp` 重连。
- **TikTok / YouTube 访问失败**：需要代理，在配置 `[tiktok] proxy` / `[youtube] proxy` 填写，如 `http://127.0.0.1:7890`。
- **YouTube 提示缺少依赖**：`brew install yt-dlp ffmpeg`。
- **改下载目录**：配置文件里设置 `output_dir`。配置模板见仓库 `config.example.toml`。
