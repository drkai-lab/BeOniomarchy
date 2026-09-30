<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/beoniomarchy-dark.png">
  <img alt="BeOniomarchy" src="docs/beoniomarchy.png" width="645">
</picture>

# BeOniomarchy v1.0

English | [日本語](README.ja.md) | [한국어](README.ko.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

BeOniomarchy turns a stock [Omarchy](https://omarchy.org) install into an
"Oniomarchy": the same machine, with a security and development workstation
on top of it.

On the name: [Oniomarchy](https://oniomarchy.com) is an existing project
by SalimRK that does this same job with a far bigger toolkit and its own
signed package repository. This repo is a different attempt at the same
idea, with its own much smaller set of tools, and it is not Oniomarchy
itself.

Everything here is nine numbered scripts. They put in the scanners and
auditors I actually reach for, the container and Kubernetes bits, a couple
of AI extras, two small API helpers for Qualys and Checkmarx, my own web
and API audit scripts with a report generator, and they fork one of
Omarchy's stock themes into an "Oniomarchy" theme.

Nothing in here is clever. Every file written, backup taken and package
installed gets one line in a state file, and that file is the only thing
`./uninstall.sh` reads when you want your machine back.

## Requirements

- Omarchy, meaning Arch Linux with the `omarchy` CLI available
- `sudo`, because packages go through pacman

## Installing

```bash
./install.sh --dry-run   # print the plan, change nothing
./install.sh             # install, asks for a yes first
./install.sh --yes       # install without asking, needed when stdin is not a tty
```

Run the dry run at least once before you let it loose. If you only want
part of the job done:

```bash
./install.sh --list            # show the modules
./install.sh --only 01,theme   # run those two only
```

Modules run in order:

| Module | What it does |
| --- | --- |
| `00-system` | directories, baseline packages, `beoni-*` links in `~/.local/bin` |
| `01-security` | nmap, lynis, clamav, yara, `beoni-audit` |
| `02-devtools` | lazygit, ripgrep, fzf, bat, eza, docker |
| `03-ai-tools` | uv, ollama |
| `04-cloud` | kubectl, helm, k9s, terraform, kustomize |
| `05-qualys` | `beoni-qualys` |
| `06-checkmarx` | `beoni-checkmarx` |
| `07-report` | writes a markdown status report |
| `08-theme` | forks a stock theme into Oniomarchy and switches to it |

## Uninstalling

```bash
./uninstall.sh --dry-run   # show what would go
./uninstall.sh --yes       # remove it
```

That restores every backup it took, deletes what it created, puts you back
on your previous theme, drops the theme fork and removes the packages it
added. It only acts on what is in the state file, so anything you installed
by hand is left alone.

`--keep-packages` and `--keep-theme` hold those parts back, `--purge` also
wipes the reports under `~/.local/share/beoniomarchy/`, and `--list` prints
the state file. If a step fails halfway the state file stays, so you can
run it again and it picks up where it stopped.

## Tools

Six commands end up in `~/.local/bin`:

```bash
beoni-webaudit https://example.com        # response security headers
beoni-apiaudit https://api.example.com    # auth, CORS, leaks
beoni-reportgen -o report.md              # machine + installer status
beoni-audit                               # listening ports and services
beoni-qualys hosts                        # Qualys API
beoni-checkmarx GET /projects             # Checkmarx API
```

The last two are the only ones that need credentials. The installer drops
`qualys.env.example` and `checkmarx.env.example` into
`~/.config/beoniomarchy/`. Copy each one to `qualys.env` and
`checkmarx.env` and fill them in.

## Where things are kept

- state and backups: `~/.local/state/beoniomarchy/`
- reports: `~/.local/share/beoniomarchy/reports/`

The state file is plain tab separated text with the types `pkg`, `create`,
`backup`, `dir`, `theme` and `themefork`. You can just `cat` it. There is
no database to dig through.
