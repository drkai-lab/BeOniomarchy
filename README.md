<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.svg">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.svg">
</picture>

# BeOniomarchy v1.0

BeOniomarchy turns an [Omarchy](https://omarchy.org) system into an
"Oniomarchy" - a security and development workstation.

## Features

- Idempotent installer driven by numbered modules
- Dry-run mode, per-module selection and full uninstall support
- Every change is recorded so `./uninstall.sh` can reverse it
- Security, dev, AI and cloud tooling
- Qualys / Checkmarx API helpers
- Web / API audit tools and a markdown report generator
- Custom "Oniomarchy" Omarchy theme

## Requirements

- Omarchy (Arch Linux + `omarchy` CLI)
- `sudo` for package installation

## Installation

```bash
./install.sh --dry-run   # preview, changes nothing
./install.sh             # install (asks for confirmation)
./install.sh --yes       # unattended install
```

Useful options:

```bash
./install.sh --list                 # show modules
./install.sh --only 01,theme        # run selected modules only
```

Modules run in order:

| Module | Purpose |
| --- | --- |
| `00-system` | Directories, baseline packages, `beoni-*` tool links |
| `01-security` | nmap, lynis, clamav, yara, `beoni-audit` |
| `02-devtools` | lazygit, ripgrep, fzf, bat, eza, docker |
| `03-ai-tools` | uv, ollama |
| `04-cloud` | kubectl, helm, k9s, terraform, kustomize |
| `05-qualys` | `beoni-qualys` API helper |
| `06-checkmarx` | `beoni-checkmarx` API helper |
| `07-report` | Markdown status report |
| `08-theme` | Forks a stock theme into the Oniomarchy theme and applies it |

## Uninstallation

```bash
./uninstall.sh --dry-run   # preview
./uninstall.sh --yes       # remove
```

Restores backed-up files, removes created files, restores the previous theme,
removes the theme fork and uninstalls packages that the installer added.
Use `--keep-packages`, `--keep-theme` or `--purge` to adjust.

## Tools

Installed as `~/.local/bin/beoni-<name>`:

```bash
beoni-webaudit https://example.com        # security header audit
beoni-apiaudit https://api.example.com    # API auth/CORS/leak audit
beoni-reportgen -o report.md              # system + installer report
beoni-audit                               # local port/service audit
beoni-qualys hosts                        # Qualys API (needs credentials)
beoni-checkmarx GET /projects             # Checkmarx API (needs token)
```

Credentials go in `~/.config/beoniomarchy/*.env` (see the `.env.example`
files created by the installer).

## State

Installer state lives in `~/.local/state/beoniomarchy/` and reports in
`~/.local/share/beoniomarchy/reports/`.
