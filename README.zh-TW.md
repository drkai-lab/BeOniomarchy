<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.png">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.png" width="645">
</picture>

# BeOniomarchy v1.0

[English](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [简体中文](README.zh-CN.md) | 繁體中文

BeOniomarchy 把一台原裝的 [Omarchy](https://omarchy.org) 變成
「Oniomarchy」：機器和桌面都不動，只在上面加一層安全與開發工作站。

先說名字。[Oniomarchy](https://oniomarchy.com) 是 SalimRK 的既有專案，
做的是同一件事，工具多得多，還自帶簽名的軟體套件倉庫。本儲存庫是對
同一個想法的另一種嘗試，工具是自己的一小套，不是 Oniomarchy 本身。

全部就是九個帶編號的腳本。裝上我平時用的掃描與稽核工具、容器與
Kubernetes 相關的東西，再加一點 AI 工具，放兩個 Qualys 和 Checkmarx
的 API 小幫手，還有我自己寫的 Web / API 稽核腳本和報告產生器，最後把
Omarchy 內建的主題 fork 一個出來叫「Oniomarchy」並切過去。

沒什麼玄機：寫了哪個檔案、備了哪份份、裝了哪個套件，都往狀態檔案裡記
一行。`./uninstall.sh` 只認這個檔案，所以狀態裡沒有的東西它不會自作
主張刪掉。

## 需要什麼

- Omarchy（裝有 `omarchy` CLI 的 Arch Linux）
- `sudo`，裝套件要走 pacman

## 安裝

```bash
./install.sh --dry-run   # 只印出計畫，不做更動
./install.sh             # 安裝，執行前會確認
./install.sh --yes       # 跳過確認；stdin 不是終端機時必須加
```

先跑一次 dry run 再說。只想裝一部分的話：

```bash
./install.sh --list            # 列出模組
./install.sh --only 01,theme   # 只跑這兩個
```

模組照編號順序執行：

| 模組 | 作用 |
| --- | --- |
| `00-system` | 目錄、基礎套件、`~/.local/bin` 裡的 `beoni-*` 連結 |
| `01-security` | nmap / lynis / clamav / yara、`beoni-audit` |
| `02-devtools` | lazygit / ripgrep / fzf / bat / eza / docker |
| `03-ai-tools` | uv / ollama |
| `04-cloud` | kubectl / helm / k9s / terraform / kustomize |
| `05-qualys` | `beoni-qualys` |
| `06-checkmarx` | `beoni-checkmarx` |
| `07-report` | 寫一份 Markdown 狀態報告 |
| `08-theme` | 把內建主題 fork 成 Oniomarchy 並切換過去 |

## 解除安裝

```bash
./uninstall.sh --dry-run   # 看看會刪掉什麼
./uninstall.sh --yes       # 真的刪
```

它會還原所有備份、刪掉自己建立的檔案、切回你原本的主題、移除主題
fork，再把自己裝的套件拿掉。只動狀態檔案裡記下的東西，所以你自己手動
裝的那些原樣留著。

`--keep-packages` 和 `--keep-theme` 分別留著不碰，`--purge` 連
`~/.local/share/beoniomarchy/` 底下的報告一起清掉，`--list` 印出狀態
檔案。中途哪一步失敗，狀態檔案還在，再跑一遍就從中斷處接著來。

## 工具

六個指令會落到 `~/.local/bin`：

```bash
beoni-webaudit https://example.com        # 回應安全標頭
beoni-apiaudit https://api.example.com    # 認證 / CORS / 洩漏
beoni-reportgen -o report.md              # 機器與安裝器狀態
beoni-audit                               # 正在監聽的連接埠與服務
beoni-qualys hosts                        # Qualys API
beoni-checkmarx GET /projects             # Checkmarx API
```

只有最後兩個需要憑證。安裝器會在 `~/.config/beoniomarchy/` 裡放
`qualys.env.example` 和 `checkmarx.env.example`，各自複製成
`qualys.env` 和 `checkmarx.env`，把值填進去就好。

## 東西放在哪

- 狀態和備份：`~/.local/state/beoniomarchy/`
- 報告：`~/.local/share/beoniomarchy/reports/`

狀態檔案是純文字，`pkg`、`create`、`backup`、`dir`、`theme`、
`themefork` 六種紀錄以定位字元分隔。`cat` 一下就能看，沒有資料庫要翻。
