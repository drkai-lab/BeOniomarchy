<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.png">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.png" width="645">
</picture>

# BeOniomarchy v1.0

[English](README.md) | 日本語 | [한국어](README.ko.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

BeOniomarchy は、そのままの [Omarchy](https://omarchy.org) を
「Oniomarchy」＝セキュリティ・開発用ワークステーションに変えるための
ツールです。マシンもデスクトップもそのままで、上に載せ替えます。

名前の件から。[Oniomarchy](https://oniomarchy.com) は SalimRK による
既存のプロジェクトで、同じことをはるかに大きなツールキットと独自の
署名付きパッケージリポジトリでやっています。こちらは同じ発想への別の
試みで、ツールは自前の小さなもの。Oniomarchy そのものではありません。

中身は番号のついたスクリプトが 9 つ。普段使いのスキャンナーと監査ツール、
コンテナと Kubernetes 周り、AI 系を少々、Qualys と Checkmarx 用の API
ヘルパー、自分用の Web / API 監査スクリプトとレポート生成、そして Omarchy
同梱テーマの 1 つを「Oniomarchy」テーマにフォークして切り替えます。

仕掛けは特に何もありません。書いたファイル、取ったバックアップ、入れた
パッケージを 1 行ずつ状態ファイルに足していくだけです。巻き戻すときは
`./uninstall.sh` がそのファイルだけを見るので、状態に無いものを勝手に
消したりはしません。

## 必要なもの

- Omarchy（`omarchy` CLI が使える Arch Linux）
- `sudo`（パッケージは pacman 経由）

## インストール

```bash
./install.sh --dry-run   # 予定を出すだけ（変更なし）
./install.sh             # インストール（実行前に確認あり）
./install.sh --yes       # 確認を飛ばす。stdin がターミナルでないときは必須
```

まずは一度ドライランを流してからにしてください。一部だけ実行したいときは:

```bash
./install.sh --list            # モジュール一覧
./install.sh --only 01,theme   # その 2 つだけ
```

モジュールは番号順に走ります:

| モジュール | やること |
| --- | --- |
| `00-system` | ディレクトリ、基本パッケージ、`~/.local/bin` への `beoni-*` リンク |
| `01-security` | nmap / lynis / clamav / yara、`beoni-audit` |
| `02-devtools` | lazygit / ripgrep / fzf / bat / eza / docker |
| `03-ai-tools` | uv / ollama |
| `04-cloud` | kubectl / helm / k9s / terraform / kustomize |
| `05-qualys` | `beoni-qualys` |
| `06-checkmarx` | `beoni-checkmarx` |
| `07-report` | Markdown のステータスレポートを書き出す |
| `08-theme` | 同梱テーマを Oniomarchy にフォークして切り替える |

## アンインストール

```bash
./uninstall.sh --dry-run   # 何が消えるかを見る
./uninstall.sh --yes       # 削除する
```

取ったバックアップを戻し、作ったファイルを消し、元のテーマに戻して、
テーマフォークを落として、自分が入れたパッケージを外します。動かすのは
状態ファイルに載っているものだけなので、手で入れたものはそのまま残ります。

`--keep-packages` と `--keep-theme` はそれぞれを触らない、`--purge` は
`~/.local/share/beoniomarchy/` 以下のレポートまで消す、`--list` は状態
ファイルを表示します。途中で失敗しても状態ファイルは残してあるので、
もう一度走らせれば止まったところから続けます。

## ツール

6 つのコマンドが `~/.local/bin` に入ります:

```bash
beoni-webaudit https://example.com        # レスポンスのセキュリティヘッダ
beoni-apiaudit https://api.example.com    # 認証 / CORS / 漏洩
beoni-reportgen -o report.md              # マシンとインストーラの状態
beoni-audit                               # 待受ポートとサービス
beoni-qualys hosts                        # Qualys API
beoni-checkmarx GET /projects             # Checkmarx API
```

認証情報が要るのは最後の 2 つだけです。インストーラが
`~/.config/beoniomarchy/` に `qualys.env.example` と
`checkmarx.env.example` を置くので、それぞれ `qualys.env` /
`checkmarx.env` にコピーして値を入れてください。

## ファイルの置き場所

- 状態とバックアップ: `~/.local/state/beoniomarchy/`
- レポート: `~/.local/share/beoniomarchy/reports/`

状態ファイルは `pkg` / `create` / `backup` / `dir` / `theme` /
`themefork` の 6 種類がタブ区切りで入ったプレーンテキストです。
`cat` で読めます。データベースとかは無いので、探す場所もありません。
