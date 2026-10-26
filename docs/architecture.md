# 免費方案下的架構設計原則

## 1. 標準架構

```
瀏覽器（表單 / 報表 / 教材）
   │  靜態資源：免費、不限量
   ▼
Worker  ── /api/*  REST API（網頁、Excel Power Query、Python）
   │    ── /mcp    MCP（Claude Code / Desktop / claude.ai）
   │    ── Queue consumer（背景：LLM 檢查、通知）
   ▼
D1（業務資料）   KV（設定、OAuth 狀態）   R2（附件，選用）   Workers AI（選用）
   ▲
Cloudflare Access（登入；程式存取用 Service Token）
```

一支 Worker、多個入口、**業務邏輯只寫一次**。

## 2. 存取 D1 的兩條路

| 方式 | 給誰 | 注意 |
|---|---|---|
| Worker 的 `env.DB` 綁定（自訂 API） | 網頁、其他程式、MCP | 依業務用途設計端點 |
| Cloudflare 官方 D1 REST API + API Token | 只限本機管理 script（例：ERP 匯入） | Token 可執行任意 SQL，**不可放前端** |

D1 **沒有**可直接連線的連線字串，一定經過上面其中一條。

## 3. 設計原則

### 資料量
- **明細留在來源系統**（ERP），D1 放收集來的資料與彙總數。
- 預算類表單用「一列 12 個月欄位」而不是「一格一列」，列數差 12 倍。
- 大量資料改成**靜態 JSON 快照**給前端讀，D1 只存使用者寫入的部分。
- 運算量大的重算放在**瀏覽器**或本機，避開 Worker 10 ms CPU 限制。

### 正確性
- 金額存整數（分）。
- 原子性用 `db.batch()`（D1 不支援互動式交易）。
- 多人編輯：**逐列存** + `updated_at` / `version` 欄位做衝突偵測，不要整包 JSON 覆蓋。
- 權限規則寫在 Worker 端，不要只靠前端隱藏。

### API / MCP
- 端點依業務用途：`GET /api/pl?bu=&month=`，**不要** `POST /api/sql`。
- MCP 新專案用 Agents SDK 的 **`createMcpHandler`**（無狀態，不需 Durable Object）；`McpAgent` 已 deprecated。
- MCP 認證用 `workers-oauth-provider`（狀態存 KV）。第一天就加，不要先部署無驗證範例。
- 要給 AI 彈性查詢：做 `query_readonly`，只允許 `SELECT`、只開放指定 view。

### LLM（Workers AI）
- **能用規則的不用 LLM**：必填、範圍、與上期差異、選擇題計分、統計都用程式 / SQL。
- LLM 只處理模糊判斷（說明合理性、申論題），**輸出視為建議**，財務與成績由人確認。
- 用 Queue 背景處理，表單送出立即回應。
- 免費額度 10,000 Neurons / 天；每次呼叫成本依模型與 token 數而定，**先實測再估**。
- 若改接外部模型（例如經 AI Gateway 呼叫 Claude API），資料會送到該供應商，需另行確認資料治理。

### 通知
- Teams / LINE / Slack webhook：免費。
- Email：免費方案只能寄到已驗證地址。

## 4. 上線前檢查清單

- [ ] 公司資安同意資料放上 Cloudflare（若經 LLM，另需同意送進 AI）
- [ ] Cloudflare Access 已保護正式網址（無痕視窗測試）
- [ ] 正式帳號為公司名義
- [ ] 報表查詢都有索引（`EXPLAIN QUERY PLAN`）
- [ ] 預估每日寫入 < 10 萬列、單庫 < 500 MB（否則改 Paid）
- [ ] 備份排程：`wrangler d1 export` 定期存檔
- [ ] repo 中沒有 token、`.dev.vars`、`.wrangler/`
- [ ] 教材 / demo 使用去識別化資料
