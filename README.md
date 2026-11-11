# dev-setup-windows-wsl

A bash bundle that will turn **Debian 13 (trixie) on WSL2** on Windows laptops into the same development
machine as the Chromebooks: a fork of
[dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) with the same four scripts
(setup, test, init, demo), the same flags and the same conventions, plus a planned Windows-host
PowerShell script for what has no Chromebook counterpart (enabling WSL, `wsl.conf` / `.wslconfig` and
the like).

**Planned, not yet built.** No scripts exist yet; the open questions in the plan come first.

Current version: none yet.

## Sibling repos

| Repo | What it is |
|---|---|
| [dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) | The original: the bundle for ChromeOS Linux (Debian 13). This repo forks it at v101 and ports fixes to and from it by hand. |
| [dev-setup-windows](https://github.com/dhouse109/dev-setup-windows) | A separate project for the same laptops using mostly native Windows tools (winget, PowerShell). |

## Where things are

| Path | What's in it |
|---|---|
| [docs/plans/wsl-plan.md](docs/plans/wsl-plan.md) | The plan: decisions so far, the WSL compatibility review, open questions, suggested sequence |
| [reference/dev-setup-chromebook/](reference/dev-setup-chromebook/) | Read-only copy of Chromebook v101, the fork source |
| [AGENTS.md](AGENTS.md) | Working rules for coding agents (`CLAUDE.md` imports it) |

## License

MIT, see [LICENSE](LICENSE). Same terms and holder as the Chromebook bundle.
