# AGENTS.md — 給 AI agent 的操作指引

這個 repo 是 Cloudflare Workers + D1 的安裝 / 開通懶人包。使用者請你「幫我設定 Cloudflare」「確認連線」「開一個 D1」時，照這份做。

資料基準日 2026-10-26。價格或限制有疑問時，用 Cloudflare 官方文件（或 Cloudflare MCP 的 `search_cloudflare_documentation`）重新確認，**不要憑記憶回答價格**。

## 1. 檢查順序（全部是唯讀）

依序執行，前一步失敗就停下來告訴使用者，不要猜。

| # | 檢查 | 指令（PowerShell 5.1） | 通過條件 |
|---|---|---|---|
| 1 | Node.js | `node --version` | ≥ v22（`npm view wrangler engines` 可確認目前要求） |
| 2 | wrangler | `wrangler --version` | 有版本號 |
| 3 | wrangler 登入 | `wrangler whoami` | 顯示 email 與 Account ID |
| 4 | D1 可用 | `wrangler d1 list` | 回傳清單（可為空） |
| 5 | R2 是否開通 | `wrangler r2 bucket list` | 錯誤碼 10042 = 尚未開通（需使用者自己綁卡） |
| 6 | MCP（若有） | 呼叫 `d1_databases_list` / `workers_list` | 有回應即代表 OAuth 已授權 |

或直接跑：`.\scripts\check-env.ps1`（結束代碼 0 = 核心工具就緒；R2 未開通不算失敗）。不要為了執行腳本而改寫或繞過使用者的 ExecutionPolicy。

### 官方插件

若 agent 支援 Agent Skills 標準，建議使用者安裝 Cloudflare 官方插件 [cloudflare/skills](https://github.com/cloudflare/skills)（Skills + MCP），安裝方式見 [docs/agent-setup.md](docs/agent-setup.md)。

- `/plugin ...` 這類 slash command 要**請使用者自己輸入**。
- 官方插件與 claude.ai 的 Cloudflare connector 會註冊重複工具，**建議擇一**；不要在使用者不知情下同時保留兩份授權。
- 官方 Skills 與本檔衝突時，**以本檔（使用者的規則）為準**。

## 2. 可以自己做的

- 安裝 wrangler：`npm install -g wrangler`
- 啟動 `wrangler login`（**放到背景執行**，它會等瀏覽器回呼；授權按鈕由使用者按）
- 建立 / 查詢 D1、寫 schema 與 migration、`wrangler dev` 本機測試
- 撰寫 Worker、前端、API、MCP server 的程式碼

## 3. 必須先問使用者的

| 動作 | 原因 |
|---|---|
| `wrangler deploy` 或任何正式部署 | 部署後網址預設**公開** |
| 把真實業務資料寫進雲端 D1 | 需確認公司資安是否允許、Access 是否已設定 |
| 刪除 D1 / KV / R2 / Worker | 不可逆 |
| 升級 Workers Paid、開通 R2 | 涉及付款 |
| 建立 Cloudflare API Token | 長期憑證，權限範圍要使用者決定 |

## 4. 絕對不做的

- **不代填信用卡或任何付款資訊**（R2 開通頁、升級頁）。請使用者自己操作。
- **不把 token / API key / `.dev.vars` commit 進 git**，也不在對話中複述。
- **不開「傳 SQL 進來執行」的公開 API 或 MCP tool**。要彈性查詢就做唯讀、限定 view 的版本（見 [docs/architecture.md](docs/architecture.md)）。

## 5. 已知坑（Windows）

- **PowerShell 5.1**：沒有 `&&`、`??`、三元運算子；串接用 `;` 或 `if ($?) { }`。
- **npm 的 allow-scripts 警告**：`npm install -g wrangler` 可能提示 `esbuild`、`workerd` 的 install script 未核准。`npm approve-scripts` **不支援 global**（EGLOBAL）。實測 `npm rebuild -g esbuild workerd` 後 esbuild 可正常執行、`@cloudflare/workerd-windows-64` 已就位即可。
- **`npx wrangler` 在非互動環境**會因為要確認安裝而中止，改用全域安裝的 `wrangler`。
- `wrangler login` 會在 `localhost:8976` 開回呼埠；若被防火牆或其他程式占用會失敗。

## 6. 免費方案的設計限制（寫程式前必看）

- D1：每天 **10 萬列寫入 / 500 萬列讀取**，單庫 500 MB，帳號 5 GB、10 個資料庫。讀取是「掃描列數」，**沒索引就是全表掃描**。
- Workers：每天 10 萬次請求，**每次 10 ms CPU**。大檔解析不要放 Worker，改在本機或瀏覽器做，再分批寫入。
- 金額用**整數**（分）存，不要用 REAL。
- D1 沒有互動式 `BEGIN…COMMIT`；要原子性就用 `db.batch()`。
- 多人編輯要**逐列存檔**並帶版本號，不要整包 JSON 覆蓋。
