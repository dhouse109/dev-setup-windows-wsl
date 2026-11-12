# dev-setup-windows-wsl

A bash bundle that turns **Debian 13 (trixie) on WSL2** on Windows laptops into the same development
machine as the Chromebooks: a fork of
[dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) with the same four scripts
(`dev-setup-wsl.sh`, `dev-test-wsl.sh`, `dev-init-wsl.sh`, `dev-demo-wsl.sh`), the same flags and the same
conventions, plus a Windows-host PowerShell script, `dev-host-wsl.ps1`, that runs first for what has no
Chromebook counterpart (enabling WSL, `wsl.conf` / `.wslconfig`, the sudoers drop-in, mkcert on Windows).

> **Current version: v1.** v1 built, not yet confirmed run in WSL. It is based on dev-setup-chromebook
> v101; the first real run is on one of the laptops. [CHANGELOG.md](CHANGELOG.md) has the history.

It is a personal lab, published as is.

## Quick start

**On Windows first**, in PowerShell, in the folder that holds the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\dev-host-wsl.ps1
```

It enables WSL, writes `.wslconfig`, installs Debian and then stops once: open Debian, create the Linux
user, exit, and run the script again. The second run writes `wsl.conf` and the sudoers drop-in, sets up
mkcert, and prints a summary and the next commands.

**Then inside Debian**, in a new terminal, with the repo cloned into the Linux home (never under `/mnt`):

```bash
git clone https://github.com/dhouse109/dev-setup-windows-wsl.git
cd dev-setup-windows-wsl

./dev-init-wsl.sh                          # 1. writes ~/.config/dev-init/secrets.env, then stops
nano ~/.config/dev-init/secrets.env        #    fill in what you have; empty is fine
./dev-setup-wsl.sh install-web             # 2. install: no flags = the base only
./dev-init-wsl.sh install-web              # 3. apply logins and config (in a new terminal)
./dev-test-wsl.sh install-web              # 4. check it all works
```

The order is **host script → init → setup → init → test**. Init runs twice because the first run only
writes the secrets template. `./dev-demo-wsl.sh <flags>` is optional and installs runnable demos into
`~/dev-demo`.

## Flags

With no flags, setup installs only the base. Group flags expand into their members, and dependencies
pull in what they need. For example, `install-web` brings `install-node` with it.

The tables are the Chromebook bundle's (v101). **Five flags are not yet supported on WSL:**
`install-lan`, `install-lan-share`, `install-android-native`, `install-retro` and `install-com`. Naming one
stops the run before anything installs, with the reason; a group that contains one, `install-all`
included, skips it with a notice. Their code is in the scripts, untouched, until each is ported.

**The base, always installed:**
- build tools, git, Python with pipx and uv
- ffmpeg, jq, shellcheck, direnv, sqlite3, psql and tmux
- Docker
- Homebrew with DDEV, gh and mkcert
- Google Chrome
- an ed25519 SSH key

### In `install-all`

| Group | Members |
|---|---|
| `install-editors` | `install-vscode` `install-windsurf` (Windsurf, now Devin Desktop) `install-cursor` `install-lazarus` (Lazarus / Free Pascal; the IDE on Qt5 with light and dark profiles, docked or floating, switched with `lazmode`; `lazmode vscode` builds and debugs a project in VS Code, Cursor or Devin) |
| `install-languages` | `install-rust` (with WASM) `install-node` (nvm, Node LTS, Claude Code, Codex, Gemini CLI, aider) `install-go` `install-pwsh` `install-ruby` (Jekyll) `install-cpp` `install-asm` `install-dotnet` (C#, VB.NET; bundle NuGet operations use IPv4) `install-java` (JDK, Maven, Gradle) |
| `install-ecosystems` | `install-antigravity` `install-media` (Flatpak, HandBrake, KDiff3) `install-gemma` (Gemma on Ollama + Gemini) `install-mobile` (Android SDK, Tauri, React Native/Expo, Flutter) `install-android-native` (Android Studio, Kotlin; **not yet supported on WSL**: skipped with a notice) `install-godot` (standard + .NET editors) |
| `install-cloud` | `install-aws` `install-azure` `install-gcp` `install-vercel` `install-cloudflare` (wrangler) |
| `install-iac` | Terraform, tflint, Bicep and `install-ansible-full` |
| `install-cache` | `install-redis` `install-memcached` |
| `install-search` | `install-solr` `install-opensearch` `install-meilisearch` `install-typesense` |
| `install-vector` | `install-qdrant` and sqlite-vec |
| `install-testing` | `install-playwright` (managed installer under assets, matching recorded browser release) `install-selenium` (Grid in Docker) `install-bdd` (Gherkin runners) `install-robot` (Robot Framework) |

`install-all` also includes these single flags:

| Flag | What it installs |
|---|---|
| `install-web` | Angular CLI, corepack, Composer, PHP extensions |
| `install-tanstack` | TanStack CLI |
| `install-drupal` | Terminus, Acquia CLI, Upsun CLI, DDEV platform tokens |
| `install-laravel` | Laravel tooling |
| `install-symfony` | Symfony tooling |
| `install-graphql` | Apollo Rover, Router and MCP Server |
| `install-k8s` | kubectl, helm, kind, k9s |
| `install-db` | ODBC, Firebird, client libraries |
| `install-db-extra` | SQLite, PostgreSQL, MariaDB and DuckDB ODBC drivers (DuckDB pinned to 1.5.6, as for the lakehouse CLI/Python) |
| `install-lakehouse` | DuckDB 1.5.6 CLI/Python, dbt Fusion and Core v1, DuckLake, Delta Lake |
| `install-agentic` | Temporal, LangGraph, Pydantic, Langfuse; bounded pip retries and stage failure reporting |
| `install-jev` | Jev |
| `install-mongodb` | MongoDB 8, mongosh, Compass |
| `install-gitlab` | glab, gitlab-ci-local |
| `install-vue` | Vue and Nuxt tooling |
| `install-herdr` | herdr, a terminal multiplexer for coding agents (pulls in `install-node`) |

The shared services (Redis, Solr, MongoDB and the rest) run in Docker on 127.0.0.1 behind one command,
`devsvc`. Only Redis and Memcached start with Linux. Everything else waits for `devsvc up NAME`, and the
heavy engines run one at a time: the rule is the 8 GB Chromebooks', kept in v1, though WSL's memory
ceiling (`.wslconfig`) is higher on these laptops.

### Opt-in only (not in `install-all`)

| Flag | What it adds |
|---|---|
| `install-db-server` | SQL Server 2025, Oracle 26ai Free (both in Docker) and InterBase: `install-mssql` `install-oracle` `install-interbase` |
| `install-oracle-full` | Oracle's full image instead of Lite |
| `install-ldap` / `install-ldap-full` | lldap in Docker / OpenLDAP + lldap |
| `install-lan` / `install-lan-share` | **Not yet supported on WSL** (waits for the Tailscale decision). On the Chromebooks: your laptops as one network (Tailscale, an address book, shared services) |
| `install-retro` | **Not yet supported on WSL** (planned for a later version). On the Chromebooks: DOS and Windows 3.1 / 95 / NT 4.0 / 2000 guests (DOSBox-X, QEMU), Open Watcom and Delphi 1 to 7 under Wine; pulls in `install-com` (COM development under Wine), also not yet supported |
| `install-models` | curated local models for Ollama (several GB) |
| `install-ollama-containers` | lets Docker containers reach Ollama |
| `install-hermes` / `install-openclaw` | personal agents |
| `install-elasticsearch` `install-milvus` `install-mongodb-atlas-local` | heavier alternatives to the shared services above |
| `install-cypress` | Cypress's system libraries |
| `install-gitlab-runner` | a GitLab Runner service |
| `install-puppet` / `install-chef` / `install-config-mgmt` | OpenVox + OpenBolt / Cinc Workstation / both |
| `install-godot-templates` | Godot export templates (~2.5 GB) |
| `install-asm-arm` | AArch64 cross toolchain + qemu-user |
| `install-cloudflared` | Cloudflare Tunnel (puts local services on the internet) |
| `install-ansible-core` | Ansible without the community collections |

## Sibling repos

| Repo | What it is |
|---|---|
| [dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) | The original: the bundle for ChromeOS Linux (Debian 13). This repo forks it at v101 and ports fixes to and from it by hand. |
| [dev-setup-windows](https://github.com/dhouse109/dev-setup-windows) | A separate project for the same laptops using mostly native Windows tools (winget, PowerShell). |

## Where things are

| Path | What's in it |
|---|---|
| `dev-host-wsl.ps1` | The Windows host script. Runs first, on Windows |
| `dev-setup-wsl.sh`, `dev-init-wsl.sh`, `dev-test-wsl.sh`, `dev-demo-wsl.sh` | The four bash scripts. They run inside the Debian WSL distro |
| [CHANGELOG.md](CHANGELOG.md) | Every version, one section per script |
| [docs/init-checklist.md](docs/init-checklist.md) | The run order, every flag, the secrets file and the manual steps |
| [docs/dev-demo.md](docs/dev-demo.md) | The demos and their disk footprint |
| [docs/wsl-gotchas.md](docs/wsl-gotchas.md) | How Debian on WSL2 differs from a Chromebook's Linux, and what the bundle does about it |
| [docs/plans/wsl-plan.md](docs/plans/wsl-plan.md) | The plan: decisions so far, the WSL compatibility review, open questions, suggested sequence |
| [docs/plans/v1-plan.md](docs/plans/v1-plan.md) | The v1 build spec, the first-run protocol and the acceptance criteria |
| [reference/dev-setup-chromebook/](reference/dev-setup-chromebook/) | Read-only copy of Chromebook v101, the fork source |
| [AGENTS.md](AGENTS.md) | Working rules for coding agents (`CLAUDE.md` imports it) |

## License

MIT, see [LICENSE](LICENSE). Same terms and holder as the Chromebook bundle.
