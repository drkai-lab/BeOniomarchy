<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.png">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.png" width="645">
</picture>

# BeOniomarchy v1.0

[English](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | 简体中文 | [繁體中文](README.zh-TW.md)

装好 Omarchy，Arch 基本就能直接用了。我在它之上又加了一套自己的工具，
让同一台机器也能干安全方面的活，这就是 BeOniomarchy，成品我叫它
"Oniomarchy"。

全部就是九个带编号的脚本。装上我平时用的扫描和审计工具、容器与
Kubernetes 相关的东西，再加一点 AI 工具，放两个 Qualys 和 Checkmarx
的 API 小助手，还有我自己写的 Web / API 审计脚本和报告生成器，最后把
Omarchy 自带的主题 fork 一个出来叫 "Oniomarchy" 并切过去。

没什么玄机：写了哪个文件、备了哪份份、装了哪个包，都往状态文件里记一行。
`./uninstall.sh` 只认这个文件，所以状态里没有的东西它不会自作主张删掉。

## 需要什么

- Omarchy（装有 `omarchy` CLI 的 Arch Linux）
- `sudo`，装包要走 pacman

## 安装

```bash
./install.sh --dry-run   # 只打印计划，不做改动
./install.sh             # 安装，执行前会确认
./install.sh --yes       # 跳过确认；stdin 不是终端时必须加
```

先跑一次 dry run 再说。只想装一部分的话：

```bash
./install.sh --list            # 列出模块
./install.sh --only 01,theme   # 只跑这两个
```

模块按编号顺序执行：

| 模块 | 作用 |
| --- | --- |
| `00-system` | 目录、基础包、`~/.local/bin` 里的 `beoni-*` 链接 |
| `01-security` | nmap / lynis / clamav / yara、`beoni-audit` |
| `02-devtools` | lazygit / ripgrep / fzf / bat / eza / docker |
| `03-ai-tools` | uv / ollama |
| `04-cloud` | kubectl / helm / k9s / terraform / kustomize |
| `05-qualys` | `beoni-qualys` |
| `06-checkmarx` | `beoni-checkmarx` |
| `07-report` | 写一份 Markdown 状态报告 |
| `08-theme` | 把自带主题 fork 成 Oniomarchy 并切换过去 |

## 卸载

```bash
./uninstall.sh --dry-run   # 看看会删掉什么
./uninstall.sh --yes       # 真的删
```

它会还原所有备份、删掉自己创建的文件、切回你原来的主题、干掉主题
fork，再把自己装的包移除。只动状态文件里记下的东西，所以你自己手动
装的那些原样留着。

`--keep-packages` 和 `--keep-theme` 分别留着不碰，`--purge` 连
`~/.local/share/beoniomarchy/` 下面的报告一起清掉，`--list` 打印状态
文件。中途哪一步失败，状态文件还在，再跑一遍就从断点接着来。

## 工具

六个命令会落到 `~/.local/bin`：

```bash
beoni-webaudit https://example.com        # 响应安全头
beoni-apiaudit https://api.example.com    # 认证 / CORS / 泄露
beoni-reportgen -o report.md              # 机器与安装器状态
beoni-audit                               # 在监听的端口和服务
beoni-qualys hosts                        # Qualys API
beoni-checkmarx GET /projects             # Checkmarx API
```

只有最后两个需要凭据。安装器会在 `~/.config/beoniomarchy/` 里放
`qualys.env.example` 和 `checkmarx.env.example`，各自复制成
`qualys.env` 和 `checkmarx.env`，把值填进去就行。

## 东西放在哪

- 状态和备份：`~/.local/state/beoniomarchy/`
- 报告：`~/.local/share/beoniomarchy/reports/`

状态文件是纯文本，`pkg`、`create`、`backup`、`dir`、`theme`、
`themefork` 六种记录用制表符分隔。`cat` 一下就能看，没有数据库要翻。
