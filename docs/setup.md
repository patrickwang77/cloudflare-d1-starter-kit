# 申請、安裝與授權

## 0. 總覽

```
① Cloudflare 帳號（免費，不需綁卡）
② 本機：Node.js 22+ → wrangler（CLI）
③ wrangler login（OAuth）      → 讓「你電腦上的 CLI」能操作你的帳號
④ Claude Code 的 Cloudflare MCP → 讓「AI 對話」能查詢 / 建立資源
⑤（選用）R2 開通（需綁卡）、Cloudflare Access（登入控管）
```

③ 和 ④ 是**兩個獨立的授權**，各自登入、各自撤銷。

## 1. 申請 Cloudflare 帳號

1. 到 <https://dash.cloudflare.com/sign-up> 註冊。
2. 驗證 email。
3. **不需要**加網域、不需要綁卡，就能用 Workers / D1 / KV 的免費方案。

> 建議：要放公司資料的正式環境，用**公司名義的帳號**（或之後把成員加進同一個 account），避免人員異動時資料歸屬不清。個人帳號適合 PoC 與教材。

## 2. 安裝元件

| 元件 | 用途 | 安裝 |
|---|---|---|
| Node.js **22 以上** | wrangler 的執行環境 | <https://nodejs.org>（LTS） |
| wrangler | Cloudflare 官方 CLI：建 D1、跑 migration、本機開發、部署 | `npm install -g wrangler` |
| git（選用） | 版本控管、接 GitHub 自動部署 | <https://git-scm.com> |

確認：

```powershell
node --version      # v22 以上
wrangler --version  # 例：4.152.0
```

### 安裝時可能看到的警告

```
npm warn allow-scripts esbuild@... (postinstall: node install.js)
npm warn allow-scripts workerd@... (postinstall: node install.js)
```

新版 npm 預設不執行套件的 install script。`npm approve-scripts` **不支援全域安裝**（會報 `EGLOBAL`）。處理方式：

```powershell
npm rebuild -g esbuild workerd
```

驗證 esbuild 能跑：

```powershell
& "$(npm root -g)\wrangler\node_modules\.bin\esbuild.cmd" --version
```

## 3. wrangler 的 OAuth 登入是什麼

### 白話說明

`wrangler login` = **讓你電腦上的 wrangler 取得一張「代表你操作 Cloudflare 帳號」的通行證**，不必把帳號密碼交給它。

流程：

```
wrangler login
   │ 1. 在本機開一個臨時接收埠 localhost:8976
   │ 2. 開瀏覽器到 dash.cloudflare.com/oauth2/auth（列出要申請的權限）
   ▼
你在瀏覽器確認帳號 → 按 Allow
   │ 3. Cloudflare 把授權碼送回 localhost:8976
   ▼
wrangler 換成 access token + refresh token，存到本機設定檔
```

- **密碼從頭到尾沒經過 wrangler**，你只是在 Cloudflare 自己的頁面按同意。
- 用的是 PKCE 流程（網址中的 `code_challenge`），授權碼被攔截也無法單獨換 token。

### token 存在哪

```
%APPDATA%\xdg.config\.wrangler\config\default.toml
```

- 這個檔案 = 你帳號的操作權限，**不要複製給別人、不要放進 git、不要放進 OneDrive 共用資料夾**。
- access token 會過期，wrangler 會用 refresh token 自動續期（申請時包含 `offline_access`）。

### 申請了哪些權限

`wrangler whoami` 會列出。常見的有：

| 權限 | 意思 |
|---|---|
| `account (read)`、`user (read)` | 讀帳號 / 使用者資訊 |
| `workers (write)`、`workers_scripts (write)` | 部署 Worker |
| `d1 (write)` | 建立 / 查詢 / 刪除 D1 |
| `workers_kv (write)` | KV |
| `pages (write)` | Pages |
| `k2.read / k2.write` | R2 相關 |
| `offline_access` | 允許自動續期 |

> **不包含 Zero Trust / Access 的設定權限**，所以 Access 要在 Dashboard 手動設定。

### 常用指令

```powershell
wrangler whoami    # 看目前登入誰、有哪些權限
wrangler logout    # 撤銷本機 token
wrangler login     # 重新登入
```

也可以到 Dashboard → 右上頭像 → **My Profile → API Tokens / Authorized apps**（名稱依介面版本可能不同）撤銷授權。

### 什麼時候不用 OAuth、改用 API Token

| 情境 | 用哪個 |
|---|---|
| 自己的電腦上開發、部署 | `wrangler login`（OAuth） |
| GitHub Actions / 排程伺服器 / 沒有瀏覽器的環境 | **API Token**：Dashboard 建立，只勾需要的權限，設為環境變數 `CLOUDFLARE_API_TOKEN` 與 `CLOUDFLARE_ACCOUNT_ID` |

API Token 權限要**最小化**（例如只給某一個 D1 的 Edit），並設到期日。

## 4. Claude Code 的 Cloudflare MCP

讓 AI 在對話中直接操作 Cloudflare（查 D1、建 KV、搜官方文件）。

1. 在 Claude Code / Claude 桌面版的連接器（Connectors）中加入 **Cloudflare Developer Platform**。
2. 依提示在瀏覽器完成 OAuth 授權。
3. 在工具權限頁，可把**唯讀工具**（list / get / search）設為「允許」、**建立 / 刪除類**維持「需要核准」。
4. 驗證：請 AI 呼叫 `d1_databases_list`，有回應即完成。

MCP 能做：D1 / KV / R2 / Hyperdrive 的查詢與建立、查看 Worker、搜尋 Cloudflare 文件。
MCP **不能**：部署程式碼（部署仍靠 wrangler）。

## 5. 驗證全部完成

```powershell
.\scripts\check-env.ps1
```

| 項目 | 預期 |
|---|---|
| Node.js | v22+ |
| wrangler | 有版本 |
| whoami | 顯示 email 與 Account ID |
| D1 | 可列出（可為空） |
| R2 | 未開通時顯示錯誤碼 10042，屬正常 |

## 6. 下一步：建第一個 D1

```powershell
wrangler d1 create my-first-db
wrangler d1 execute my-first-db --remote --command "CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)"
wrangler d1 execute my-first-db --remote --command "SELECT * FROM t"
```

> `--remote` 操作雲端資料庫；不加則是本機模擬資料庫（`.wrangler/` 資料夾）。開發時先用本機。

## 7. 部署前必做：Cloudflare Access

部署後的 `*.workers.dev` 網址**預設任何人都能開**。放真實資料前：

1. Dashboard → **Zero Trust**（第一次進入會要求建立 team name，並選擇方案；選 Free）。
2. **Access → Applications → Add an application → Self-hosted**。
3. 網域填你的 Worker 網址；Policy 設「Emails ending in `@你的公司網域`」或指定 email 清單。
4. 驗證：用無痕視窗開網址，應出現 Access 登入頁。

> Zero Trust 開通流程中是否要求付款資訊、免費席次上限，**本文未能查證**，以畫面為準；若要求輸入卡號，同樣請本人操作。
