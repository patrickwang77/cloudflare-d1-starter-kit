# Cloudflare D1 懶人包（給人看，也給 AI agent 看）

用 Cloudflare **Workers + D1（+ 選用 R2 / Workers AI）** 建「表單收集 → 資料庫 → 報表 / API / MCP」的安裝與開通指南。

> 資料基準日：**2026-10-26**，價格與額度取自 Cloudflare 官方文件當天版本。
> Cloudflare 會調整方案（例如 2026-07 起部分 Workers AI 大模型改為付費限定），**正式採用前請再對照官方頁面**。

## 給 AI agent

先讀 **[AGENTS.md](AGENTS.md)**：裡面有檢查順序、可直接執行的指令、以及哪些動作**必須先問使用者**。

## 文件導覽

| 文件 | 內容 |
|---|---|
| [docs/pricing.md](docs/pricing.md) | 適用 / 不適用情境、免費與付費額度、用量估算方法 |
| [docs/setup.md](docs/setup.md) | 申請帳號、安裝元件、**wrangler OAuth 登入是什麼**、Claude Code MCP 連線 |
| [docs/r2.md](docs/r2.md) | R2 開通（需綁卡）、不綁卡的替代方案、防止意外扣款 |
| [docs/architecture.md](docs/architecture.md) | 在免費方案下的設計原則：API、MCP、Workers AI、登入控管 |
| [scripts/check-env.ps1](scripts/check-env.ps1) | 一鍵檢查本機環境與登入狀態（唯讀，不改任何設定） |

## 三分鐘結論

- **適合**：內部表單收集（預算、預測、回填）、彙總報表、教材 demo、線上測驗、小型資料 API。
- **不適合（免費方案）**：每天寫入超過 10 萬列、單庫超過 500 MB、把 ERP 明細整包鏡像上雲。
- **不綁卡就不會被扣款**：免費方案超量時是「失敗」而不是「計費」。R2 是唯一需要綁卡才能開的元件。
- **部署出去的網址預設公開**：放真實資料前，先用 Cloudflare Access 加登入。

## 快速開始（Windows）

```powershell
# 1. 需要 Node.js 22 以上（wrangler 4.x 的要求）
node --version

# 2. 安裝 wrangler
npm install -g wrangler

# 3. OAuth 登入（會開瀏覽器，按 Allow）
wrangler login

# 4. 檢查環境
.\scripts\check-env.ps1
```

> 若出現「已停用指令碼執行」，代表執行原則是 `Restricted`；Windows 預設的 `RemoteSigned` 可直接執行本機腳本。

細節與常見錯誤見 [docs/setup.md](docs/setup.md)。
