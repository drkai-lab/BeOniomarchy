<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.png">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.png">
</picture>

# BeOniomarchy v1.0

BeOniomarchy は [Omarchy](https://omarchy.org) を「Oniomarchy」= セキュリティ・開発用ワークステーションへ変換するツールキットです。

## 機能

- 番号付きモジュールによる冪等なインストーラ
- ドライラン、モジュール単位の実行、完全なアンインストール対応
- 変更内容をすべて記録し `./uninstall.sh` で復元可能
- セキュリティ / 開発 / AI / クラウドツールの導入
- Qualys / Checkmarx API ヘルパー
- Web / API 監査ツールと Markdown レポート生成
- カスタムテーマ「Oniomarchy」の適用

## 必要環境

- Omarchy（Arch Linux + `omarchy` CLI）
- パッケージ導入用の `sudo`

## インストール

```bash
./install.sh --dry-run   # 確認のみ（変更なし）
./install.sh             # インストール（確認あり）
./install.sh --yes       # 無人インストール
```

主なオプション:

```bash
./install.sh --list               # モジュール一覧
./install.sh --only 01,theme      # 指定モジュールのみ実行
```

| モジュール | 内容 |
| --- | --- |
| `00-system` | ディレクトリ・基本パッケージ・`beoni-*` ツールのリンク |
| `01-security` | nmap / lynis / clamav / yara、`beoni-audit` |
| `02-devtools` | lazygit / ripgrep / fzf / bat / eza / docker |
| `03-ai-tools` | uv / ollama |
| `04-cloud` | kubectl / helm / k9s / terraform / kustomize |
| `05-qualys` | `beoni-qualys` API ヘルパー |
| `06-checkmarx` | `beoni-checkmarx` API ヘルパー |
| `07-report` | Markdown ステータスレポート生成 |
| `08-theme` | ストックテーマを Oniomarchy にフォークして適用 |

## アンインストール

```bash
./uninstall.sh --dry-run   # 確認のみ
./uninstall.sh --yes       # 削除
```

バックアップしたファイルの復元、作成ファイルの削除、元のテーマへの復帰、
テーマフォークの削除、インストーラが追加したパッケージの削除を行います。
`--keep-packages` / `--keep-theme` / `--purge` で挙動を調整できます。

## ツール

`~/.local/bin/beoni-<名前>` として導入されます:

```bash
beoni-webaudit https://example.com        # セキュリティヘッダ監査
beoni-apiaudit https://api.example.com    # API 認証/CORS/漏洩監査
beoni-reportgen -o report.md              # システム+インストーラ状態レポート
beoni-audit                               # ローカルポート/サービス監査
beoni-qualys hosts                        # Qualys API（要認証情報）
beoni-checkmarx GET /projects             # Checkmarx API（要トークン）
```

認証情報は `~/.config/beoniomarchy/*.env` に設定します
（インストーラが作成する `.env.example` を参照）。

## 状態ファイル

インストーラの状態は `~/.local/state/beoniomarchy/`、
レポートは `~/.local/share/beoniomarchy/reports/` に保存されます。
