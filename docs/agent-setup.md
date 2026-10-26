# AI agent 接 Cloudflare：官方插件 vs connector

資料基準日 2026-10-26，來源：Cloudflare 官方
[Agent setup](https://developers.cloudflare.com/agent-setup/) ·
[Servers for Cloudflare](https://developers.cloudflare.com/agents/model-context-protocol/cloudflare/servers-for-cloudflare/)

## 1. Cloudflare 官方發布的三個 repo

都在 `github.com/cloudflare` 底下，**不是個人作品**。

| repo | 內容 | 什麼時候用 |
|---|---|---|
| **[cloudflare/skills](https://github.com/cloudflare/skills)** | **官方插件**：Skills（Cloudflare 平台知識，含 wrangler Skill）+ 自動註冊 Cloudflare MCP servers + slash commands | **首選**，一次裝好 |
| [cloudflare/mcp](https://github.com/cloudflare/mcp) | Code Mode API MCP（`mcp.cloudflare.com/mcp`）：只有 `search()` / `execute()` 兩個工具，覆蓋 2,500+ 個 API | 要操作 DNS、WAF、Zero Trust 等整個 Cloudflare API |
| [cloudflare/mcp-server-cloudflare](https://github.com/cloudflare/mcp-server-cloudflare) | 依產品分開的 MCP servers（例：Developer Platform、Docs、Observability） | 只需要某個產品；claude.ai 的「Cloudflare Developer Platform」connector 屬於這類 |

三者分工（官方 FAQ 的說法）：**Skills** 給知識、**MCP** 做平台操作、**wrangler** 做本機開發與部署。官方插件會把三者一起設定好。

另有 **`cf` CLI（beta）**：涵蓋整個 Cloudflare API、輸出 JSON，`npm install -g cf` → `cf auth login`。本懶人包仍以 wrangler 為主。

## 2. 各 harness 安裝方式

插件支援 **Agent Skills 標準**，同一份內容可用在多種 agent。

| Agent | 安裝 |
|---|---|
| **Claude Code** | 在 Claude Code 內輸入：<br>`/plugin marketplace add cloudflare/skills`<br>`/plugin install cloudflare@cloudflare` |
| **OpenAI Codex** | CLI 內輸入 `/plugins`，搜尋並安裝 **Cloudflare**；桌面版在 **Plugins** 頁安裝 |
| **Cursor** | `/add-plugin cloudflare`，或從 Cursor Marketplace 安裝；手動：Settings → Rules → Add Rule → Remote Rule (Github) → `cloudflare/skills` |
| **Droid**（Factory） | `droid plugin marketplace add https://github.com/cloudflare/skills`<br>`droid plugin install cloudflare@skills` |
| **其他（npx skills）** | `npx skills add https://github.com/cloudflare/skills` |

> slash command（`/plugin ...`）要**使用者自己在 agent 介面輸入**；agent 通常無法替你執行。

### 手動複製 Skills（不想裝插件時）

clone `cloudflare/skills` 後，把 skill 資料夾複製到各 agent 的目錄：

| Agent | Skill 目錄 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Cursor | `~/.cursor/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| OpenAI Codex | `~/.codex/skills/` |
| Pi | `~/.pi/agent/skills/` |

手動複製只有 Skills，**不會**註冊 MCP servers。

### 驗證

- Claude Code：`claude mcp list` 看 Cloudflare servers 是否已連線；插件裝完沒出現就 `/reload-plugins`。
- 第一次呼叫 Cloudflare 工具時會跳 OAuth 授權頁，選擇要授予的權限。
- CI/CD 或沒有瀏覽器的環境：不走 OAuth，改用 Cloudflare API Token 當 bearer token。

## 3. 官方插件 vs claude.ai connector：擇一

| | 官方插件（cloudflare/skills） | claude.ai connector（Developer Platform） |
|---|---|---|
| 包含 | Skills + 多個 MCP servers + slash commands | 單一 MCP server（D1 / KV / R2 / Hyperdrive / Workers 查詢、文件搜尋） |
| 可用的 agent | Claude Code、Codex、Cursor、OpenCode、Pi、Droid… | Claude 系列（claude.ai、Desktop、Code）；**其他 agent 要各自另接** |
| 平台知識 | 有（Skills） | 沒有 |
| 不能裝 CLI 的環境（手機、claude.ai 網頁版） | 不適用 | **可用** |
| 部署 | 仍靠 wrangler | 不能部署 |

**建議**

- **本機開發用的 Claude Code / Codex / Cursor → 裝官方插件**，並中斷 claude.ai 的 Cloudflare connector，避免同一組工具註冊兩次、各自一份 OAuth 授權。
- **只在 claude.ai 網頁或手機上查詢 → 保留 connector** 即可。
- 兩者都是能操作你帳號的入口；不用的那個就中斷，並到 Cloudflare Dashboard 撤銷對應授權。
- 工具權限：唯讀（list / get / search）可設「允許」；建立 / 刪除 / 部署維持「需要核准」。

## 4. 官方插件和本懶人包的分工

| | 官方插件 | 本懶人包 |
|---|---|---|
| 提供 | 通用 Cloudflare 知識 | **你的**決策與限制 |
| 例 | wrangler 指令、D1 vs KV 怎麼選、專案結構 | 只用免費方案、R2 不綁卡、部署前先問、PowerShell 5.1 的坑、ERP 為唯一正式帳 |
| 被誰讀 | 裝了插件的 agent | 任何讀 `AGENTS.md` 的 agent（Claude Code 透過 `CLAUDE.md` 載入） |

兩者衝突時，以本懶人包（使用者的規則）為準；價格與功能有疑問時，以 Cloudflare 官方文件為準。
