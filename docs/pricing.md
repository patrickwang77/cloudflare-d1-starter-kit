# 適用情境與費用（截至 2026-10-26）

來源：Cloudflare 官方文件
[D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/) ·
[D1 limits](https://developers.cloudflare.com/d1/platform/limits/) ·
[R2 pricing](https://developers.cloudflare.com/r2/pricing/) ·
[Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) ·
[Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/)

## 1. D1 與 R2 各做什麼

| | D1 | R2 |
|---|---|---|
| 本質 | 邊緣節點上的 SQLite | S3 相容物件儲存 |
| 放什麼 | 表單資料、彙總數、主檔、測驗紀錄 | 附件、PDF、匯出檔、備份 |
| 強項 | SQL（JOIN / GROUP BY）、跟 Workers 原生綁定 | 便宜、**egress 免費** |
| 限制 | 單庫最大 10 GB（不可調高）、單執行緒寫入 | 不能查詢內容 |

## 2. 適用 / 不適用

**適用**
- 內部表單收集：銷售預測、費用預算、交期回填
- 彙總報表：科目 × 部門 × 月、預算 vs 實際
- 互動教材、線上測驗（作答紀錄、評分）
- 給 Excel Power Query / Python / 其他網頁用的小型資料 API
- 給 AI 用的 MCP server

**不適用（免費方案）**
- 把 ERP 明細整包鏡像上雲（每月 10 萬筆明細 + 索引會超過每日寫入上限）
- 單次匯入幾十萬列（例：一期 94 萬列要分 10 天才寫得完）
- 需要 SLA 或原廠支援的正式帳務系統

> 原則：**ERP 仍是唯一正式帳**；Cloudflare 放「收集來的資料」與「彙總數」，明細追查回 ERP。

## 3. 免費 vs 付費

付費 = **Workers Paid，每帳號每月 US$5**（含 Workers / D1 / KV / Durable Objects 的較高額度）。

### D1

| 項目 | Workers Free | Workers Paid 含量 | 超量單價 |
|---|---|---|---|
| Rows read | 500 萬 / **天** | 250 億 / 月 | $0.001 / 百萬列 |
| Rows written | 10 萬 / **天** | 5,000 萬 / 月 | $1.00 / 百萬列 |
| 儲存 | 帳號共 5 GB | 5 GB | $0.75 / GB-月 |
| 單庫上限 | 500 MB | 10 GB | — |
| 資料庫數 | 10 | 50,000 | — |
| Time Travel（還原） | 7 天 | 30 天 | — |
| 每次 Worker 呼叫的查詢數 | 50 | 1,000 | `db.batch()` 算 1 次 |

- 免費方案每天 00:00 UTC（台灣 08:00）重置；**自 2026-09-01 起，超量的查詢會直接失敗**，資料不受影響。
- Rows read 算「掃描列數」不是「回傳列數」；Rows written 每多一個受影響的索引 +1。

### Workers

| | Free | Paid |
|---|---|---|
| 請求數 | 10 萬 / 天 | 1,000 萬 / 月，超量 $0.30 / 百萬 |
| CPU | **10 ms / 次** | 3,000 萬 CPU-ms / 月，超量 $0.02 / 百萬 ms |
| 靜態資源請求 | 免費且不限量 | 同左 |

### R2（Standard）

| 項目 | 每月免費 | 超量 |
|---|---|---|
| 儲存 | 10 GB | $0.015 / GB-月 |
| Class A（PUT、LIST） | 100 萬次 | $4.50 / 百萬 |
| Class B（GET、HEAD） | 1,000 萬次 | $0.36 / 百萬 |
| Egress | 免費 | 免費 |

Infrequent Access：$0.01 / GB-月、Class A $9、Class B $0.90、取回 $0.01/GB、最短計費 30 天、**沒有免費額度**。

> **R2 開通必須綁付款方式**，即使只用免費額度。見 [r2.md](r2.md)。

### 其他常用元件

| 元件 | 免費方案 | 備註 |
|---|---|---|
| Workers AI | 10,000 Neurons / 天 | 2026-07 起 kimi-k2.6 / kimi-k2.7-code / glm-5.2 限付費；免費仍可用 glm-4.7-flash、gemma-4-26b、nemotron-3-120b 等 |
| Queues | 10,000 次操作 / 天，保留 24 小時 | 2026-02 起開放免費方案 |
| Email Sending | **只能寄到已驗證的收件地址** | 寄任意收件者需 Paid（含 3,000 封 / 月） |
| Durable Objects | 只有 SQLite backend | — |
| Cloudflare Access | 有免費方案 | 免費席次上限本文**未能從官方頁面查證**，請以 Zero Trust 方案頁為準 |

## 4. 怎麼估自己的用量

1. **每筆寫入列數** = 1 + 受影響的索引數
2. **每日寫入** = 每日新增筆數 × (1 + 索引數)，對照 10 萬
3. **儲存** = 筆數 × 平均列大小 × ~1.5（含索引），對照單庫 500 MB
4. **讀取**：報表查詢要能用到索引；用 `EXPLAIN QUERY PLAN` 確認沒有 `SCAN TABLE`

範例（每月 10 萬筆、每筆約 1 KB、3 個索引）：

| | 每月 | 免費方案 | Paid |
|---|---|---|---|
| 寫入 | ~40 萬列 | 平均每天 1.3 萬，OK；**月底一次匯入會爆** | 遠低於 5,000 萬 |
| 儲存 | +150 MB | **約 3 個月塞滿單庫** | 第 3 年才超過 5 GB |
| 費用 | — | $0 | 約 $5–8 / 月 |

→ 明細量級的資料用 Paid；只放彙總數則免費方案就夠。
