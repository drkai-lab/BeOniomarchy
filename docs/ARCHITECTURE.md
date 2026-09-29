# Architecture

BeOniomarchy consists of:

- **installer layer** - `install.sh` / `uninstall.sh` entry points
- **shared library** - `lib/common.sh` (logging, dry-run, package and file
  helpers, state recording)
- **module scripts** - `modules/NN-<name>.sh`, sourced context, run in
  numeric order by the installer
- **helper tools** - `tools/webaudit`, `tools/apiaudit`, `tools/reportgen`
  (standalone CLIs, linked into `~/.local/bin/beoni-*`)
- **documentation**

## Module contract

Every module:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
```

and then uses only library helpers for anything with side effects:

| Helper | Effect |
| --- | --- |
| `pkg_add pkg...` | install missing packages, record them |
| `ensure_dir path` | create a directory, record it |
| `install_file src dst [mode]` | back up `dst` if present, copy, record |
| `write_file dst [mode]` | like `install_file`, content from stdin |
| `backup_file src` | save the original once (never re-backed up) |
| `run cmd...` | execute, or print only in dry-run mode |
| `dry_log msg` | dry-run-only message |

## State file

`~/.local/state/beoniomarchy/state.tsv`, tab separated:

```
pkg       <package>
create    <path>
backup    <original-path> <backup-path>
dir       <path>
theme     <previous-theme>
themefork <theme-directory>
```

`install.sh` and all modules share one `BEONI_RUN_ID`, so backups of a run
land in `~/.local/state/beoniomarchy/backups/<run-id>/`.

## Uninstall order

1. restore the previous theme (only if Oniomarchy is active)
2. restore every `backup` record
3. delete every `create` record (HOME paths only)
4. delete `themefork` directories (theme paths only)
5. remove empty `dir` records
6. remove `pkg` records via pacman (unless `--keep-packages`)

Anything unexpected is refused with a warning instead of guessed at; if any
step fails the state file is kept so the uninstall can be retried.
