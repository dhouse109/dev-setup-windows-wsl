# AGENTS.md — dev-setup-windows-wsl

Guidance for coding agents working in this repository (Claude Code, Codex, or any other). Read this first,
then `docs/plans/wsl-plan.md`, then the plan for the version you are building (`docs/plans/vNN-plan.md`,
once versions exist).

`AGENTS.md` holds the shared rules. `CLAUDE.md` is a regular file importing it with `@AGENTS.md`.
Edit `AGENTS.md`; do not duplicate the rules or replace `CLAUDE.md` with a symlink. Keep tracked files
free of symlinks: Git for Windows often checks them out as plain text files (CI checks for them).

Adapted from dev-setup-chromebook's `AGENTS.md` at v101 (copy in `reference/dev-setup-chromebook/`).
`reference/dev-setup-chromebook/AGENTS.md` is that repo's rules file: it describes the Chromebook repo,
not this one. The copy leaves out that repo's `CLAUDE.md` on purpose, so its `@AGENTS.md` import never
loads the Chromebook rules into a session here.

## What this repo is

A fork of the Chromebook dev bundle that turns **Debian 13 (trixie) on WSL2** on the owner's Windows
laptops into the same development machine the Chromebooks are: same flags, same four scripts, same
conventions. Most tools install inside WSL as Linux tools, just as on a Chromebook. It is a personal lab,
published as is. The owner decides what goes in and runs every version on the laptops; the coding agent
drafts, reviews and fixes the scripts.

**Status: planning; nothing is built.** Decisions for v1 are recorded: open questions 1–7 and 13 were settled on 2026-11-11. Next comes the WSL review of v77–v101, then the v1 plan; the scripts start after the v1 plan.

The scripts to come (names decided 2026-11-11, open question 2 in `docs/plans/wsl-plan.md`):

| Script | Role |
|---|---|
| `dev-host-wsl.ps1` | Windows host (PowerShell). Runs first, on Windows: enables WSL and installs the distro, writes `wsl.conf` / `.wslconfig`, and covers what has no Chromebook counterpart. Scope in the plan. |
| `dev-setup-wsl.sh` | Installer. Unattended, idempotent, safe to rerun. Runs inside the Debian WSL distro. |
| `dev-init-wsl.sh` | Logins, API keys and config, read from `~/.config/dev-init/secrets.env`. |
| `dev-test-wsl.sh` | Verifies every installed component works (PASS/FAIL/WARN/SKIP) and writes a per-stack disk report. |
| `dev-demo-wsl.sh` | Optional. Installs runnable demos into `~/dev-demo`. Outside the test/checklist loop. |

The `-wsl` names keep them apart from dev-setup-windows' native scripts on the same laptop.

The four bash scripts take the **same flags** with the **same flag-expansion logic** as the Chromebook
bundle (the `FLAG EXPANSION` block near the top of each script: `install-all` → groups → members →
dependencies). A flag added to one script is added to all four, even if some only expand it.

Run order: **`dev-host-wsl.ps1` on Windows first**, then **init → setup → init → test** inside WSL, as on
the Chromebooks (first init only writes the secrets template).

What exists now: `docs/plans/wsl-plan.md` (decisions, the WSL compatibility review, open questions),
`reference/dev-setup-chromebook/` (read-only copy of Chromebook v101, the fork source), lint CI, and an
MIT `LICENSE`.

## Target environment

- **Windows 11 22H2 or later** (the minimum, needed when mirrored networking comes with Q8), **WSL2,
  Debian 13 (trixie), x86-64.**
- Machines (details in `docs/plans/wsl-plan.md`, "Target machines"):

  | Machine | CPU | RAM | Disk | GPU |
  |---|---|---|---|---|
  | 109.hpe.d3 | Ryzen 5 5500U | 32 GB | 1 TB | Radeon iGPU |
  | 109.hpe.d1 | i7-1065G7 | 16 GB | 1 TB | GeForce MX330, 2 GB |
  | 109.hpp.d2 | i5-10210U | 16 GB | 1 TB | Intel UHD |
  | 109.hpr.d4 | Pentium Silver N5030 (no AVX/AVX2) | 32 GB | 500 GB | Intel UHD 605 |

  First real runs are on d3. d4 gets a run before the bundle is called done: it has no AVX, so MongoDB
  5+ can't run there. One bundle for all four, no tiers; flags are chosen per machine.

- **WSL hazards** the scripts must handle (the plan's compatibility review has the full list and fixes):
  - **systemd** must be on (`[boot] systemd=true` in `/etc/wsl.conf`, then `wsl --shutdown`); Docker,
    kind, Langfuse and the Ollama drop-in need it, and Debian's WSL image likely leaves it off. The host
    script sets it.
  - **Windows PATH interop:** Windows `npm` / `code` shims on the appended Windows PATH can satisfy
    `command -v` checks when the Linux tool is missing. The host script sets `appendWindowsPath=false`
    in `wsl.conf`.
  - **`/mnt/*`:** the bundle never runs from the Windows filesystem (`/mnt/c/...`): exec bits, setuid
    sandboxes, pipx and venv paths break, and it is slow. It lives in the Linux home.
  - **CRLF:** a script that passed through Windows Git or a Windows editor fails with
    `$'\r': command not found`. `.gitattributes` keeps every text file LF (`*.ps1` CRLF).
  - **Memory cap:** WSL gets 50% of host RAM by default. The host script sizes `.wslconfig` (about 75%
    of host RAM, plus swap, and `sparseVhd=true` written before the distro is installed).
  - **inotify watches** may be low. The test's check is a WARN, not a FAIL, and its hint names the
    `sysctl`; no setup or host-script step raises the limit unless a laptop shows it is needed.
  - **Docker Desktop:** its WSL integration conflicts with docker-ce inside the distro. The bundle uses
    docker-ce; setup's preflight stops if the integration is on for this distro. The host script checks
    and reports it, and doesn't change Docker Desktop's settings.
  - Also: GPU is WSLg's `/dev/dxg` + Mesa D3D12 (no virgl, `renderD128` or sommelier); links open in
    the Windows default browser through the bundle's own opener in `~/.local/bin`, which calls Windows
    by absolute path (no `wslu` / `wslview`); disk freed inside WSL does not return to Windows unless
    the VHDX is sparse or is compacted.

## Where you are running

Check this before running anything. The host guard at the top of every script will exit on anything that
isn't **WSL + Debian** (WSL detected by `$WSL_DISTRO_NAME` or `/proc/sys/fs/binfmt_misc/WSLInterop`;
Debian by `/etc/os-release`), replacing the Chromebook bundle's ChromeOS + Debian check. **A bypass such
as `DEV_BUNDLE_ANY_HOST=1` is never used to force it**, in either case below.

**In a cloud sandbox** (Claude Code on the web, Codex cloud, CI): this is not one of the laptops and not
WSL. Do not run setup, init, test, demo or the host script, from this repo or from `reference/`. Cloud
work is seeding, static review and preliminary builds: edits, `bash -n`, `shellcheck -S error`, CI. Real
runs happen in WSL on the laptops; the owner pastes the end of a test run back into the session.

**Nothing from the scripts is executed or sourced in the cloud, including a fragment extracted from
one.** Logic is checked by reading, `bash -n` and `shellcheck` only. (v1, Nov 11 2026: an extracted
fragment skipped the host guard and ran setup's body in the sandbox.)

**Locally, inside the Debian WSL distro on one of the laptops** (an agent started in the owner's WSL
terminal; the repo is cloned into the Linux home, **never under `/mnt/c` or any `/mnt/*` path**):

- Go ahead without asking: read anything in the repo, including `assets/logs/` (git-ignored, so read it
  by path; once the scripts exist, setup and test save their screen output there as
  `<script>-<date-time>.output`, and test writes a `.log` with the same date-time); `bash -n`,
  `shellcheck -S error`; read-only inspection (`<tool> --version`, `dpkg-query`, `command -v`, `du`,
  `docker ps`, `docker system df`).
- Ask the owner first: running setup, init, test or demo (they install, use `sudo`, start services, and
  take a long time), the Windows host script or any Windows-side command (`wsl.exe`, `powershell.exe`,
  `winget`), any other `sudo` command, and anything that writes outside the repo. When the owner runs a
  script, give the exact command and flags, and read its `.output` file afterwards instead of asking for
  a paste.
- If the sandbox blocks a command you need (git push/fetch, gh, sudo, a network download), request
  approval to run that one command outside the sandbox; the owner approves or declines it in the
  prompt. Never change sandbox or approval settings yourself, and never use a bypass flag.
  In a cloud sandbox, say so and hand the owner the command instead.
- **Never open, print or copy credentials**: `~/.config/dev-init/secrets.env`, `~/.codex/auth.json`,
  `~/.claude/`, `gh`'s `hosts.yml`, `~/.ssh/`, cloud CLIs' config, and their Windows-side counterparts
  under `/mnt/c/Users/...`. To check a key is set, the scripts already report that without showing it.
- The laptop is the owner's working machine and WSL shares its RAM with Windows: don't start heavy
  services (Ollama models, database containers, an Android emulator) to test something without asking.

## Rules that never change

1. **One version number for the bundle.** Numbering starts at **v1** (based on Chromebook v101). Any
   change to any script bumps **all five** to the same version, including scripts with no code change
   ("version bump only" in the changelog): `dev-setup-wsl.sh`, `dev-init-wsl.sh`, `dev-test-wsl.sh`,
   `dev-demo-wsl.sh` and `dev-host-wsl.ps1`. Every place the version string appears gets updated. The
   list of those places and the `grep` that must show only the new number come with the v1 build, once
   the forked scripts and the host script's version line exist (the Chromebook bundle's list is in
   `reference/dev-setup-chromebook/AGENTS.md`, rule 1).
2. **CHANGELOG.md** has one section per script (five, including the host script), newest version first.
   Every version gets an entry under every script; a script with no change gets "version bump only".
   Each entry says whether it ports to dev-setup-chromebook (yes / no / n.a.).
3. **Code comments carry the why**, tagged with the version that added them and, for fixes, the dated
   finding (`# v1: … (Nov 20 2026: …)`). Keep existing tagged comments; they are the design record.
   **Inherited comments:** the fork keeps the Chromebook scripts' tagged comments. A Crostini comment
   goes only when the code it explains changes or is removed, and its replacement is tagged `v1:` (or
   the current version) with the WSL reason.
4. **Nothing loose in `$HOME`.** Files the scripts create for the user to keep (logs, downloads,
   generated helpers, disk-report TSVs) go in `./assets` next to the scripts (`$ASSETS`). Commands go in
   `~/.local/bin`; config in `~/.config/...`.
5. **Secrets only in `~/.config/dev-init/secrets.env`** (mode 600) inside the WSL distro. Never in the
   scripts, never in the repo. `*_ONCE` values are used once and never exported.
6. **Every hosting-platform or cloud token is optional.** Installing never forces getting a key; init
   reports an unconfigured platform as a skip, not a todo.
7. **Setup is unattended and idempotent.** No interactive prompts in setup. Each step is guarded so a
   rerun skips what is done and a hand-configured machine is brought into line, not clobbered.
8. **Homebrew goes last on PATH** so its dependencies (python3, sqlite3, openjdk, binutils) never shadow
   Debian's.
9. **Downloads are verified** where the vendor publishes a checksum, and validated (`gzip -t`,
   `dpkg-deb --info`, a test run) before they replace anything. Prefer reading installed versions
   (`dpkg-query`) over hardcoding them in paths.
10. **Two bundles, never platform-aware.** This bundle is not made platform-aware for ChromeOS, and the
    Chromebook repo is not made platform-aware for WSL. Fixes are ported between them by hand, each
    release note saying whether it ports. Scope: CLIs and system-level tools belong here behind flags;
    SDKs and frameworks used by one project stay per-project and out of the bundle. Native Windows
    tooling is a third repo (`dev-setup-windows`).
11. **Bring your own media.** Never add downloads of Windows, DOS, Delphi, InterBase or other licensed
    media; the scripts install only from files the user places in the named folders.

## Keeping in step with dev-setup-chromebook

- **Diffable fork.** Same flag names, same section order and same section headings as the Chromebook
  scripts, so `diff -u` between a script here and its original in `reference/dev-setup-chromebook/`
  shows only real platform differences. Don't reorder, rename or reformat sections for taste; make each
  WSL change a straight edit where the Chromebook code is.
- **Porting fixes.** When a Chromebook release fixes something platform-neutral, apply the same fix here
  (and the reverse). The changelog entry on each side says "ports to the other bundle: yes / no / n.a.".
- **A shared `dev-common.sh`** comes only later, and only if porting fixes twice becomes a chore, since
  it touches the Chromebook bundle.
- **`reference/` is read-only.** Never edit it, lint it or run it. To refresh it from a newer Chromebook
  tag, in a commit of its own:
  1. Fetch the tag from dev-setup-chromebook (`git fetch --depth 1 origin tag vNN` in a clone of that
     repo).
  2. Delete `reference/dev-setup-chromebook/` and extract the same file list from the tag with
     `git archive vNN <files> | tar -x -C reference/dev-setup-chromebook` (the four scripts,
     `CHANGELOG.md`, `README.md`, `AGENTS.md`, `LICENSE`, `docs/`; never `CLAUDE.md`), so the copy is
     byte for byte.
  3. Update `reference/README.md` (tag, commit SHA, copy date) and the fork-source line in
     `docs/plans/wsl-plan.md`.
  4. Then, in later commits, review the Chromebook CHANGELOG between the old and new tags and port what
     applies.

## When you change a flag or a stack

Once the scripts exist, update in the same change:
- all four bash scripts (flag expansion at minimum), and the host script if the change has a Windows side
- the **"not yet supported on WSL" list**: flags not yet ported are refused at flag expansion from one
  short list. Naming a refused flag directly stops before anything installs, with the reason; any
  group, including `install-all`, skips a refused member with a notice (v1's list: install-lan,
  install-lan-share, install-android-native, install-retro, install-com; the v77–v101 review may add to
  it). A flag that becomes supported comes off the list in all four scripts
- test: checks for the new behaviour (`check` = FAIL if missing, `warn` for user-changeable settings),
  and the disk report's line for that stack
- the init checklist doc: run order, flags, secrets variables, manual steps
- the demo doc if the demo changed (what it does, downloads, disk footprint)
- `README.md`: the flag tables, and "Current version"
- a WSL gotchas doc (the counterpart of the Chromebook's `docs/crostini-gotchas.md`) if the change works
  around a WSL difference
- `CHANGELOG.md` (every script's section, with the "ports" note)

## Workflow

- **Plans first.** Each version is planned in `docs/plans/vNN-plan.md` before it is built. The owner
  approves plan choices; if the plan doesn't settle something, ask rather than guess.
- **One branch per version** (`release/vNN`), PR into `main`. Plans go in on their own branch
  (`plan/vNN`). Never name a branch plain `vNN`: that is the release tag, and a branch with the same name
  makes `git checkout vNN` ambiguous (it happened with Chromebook v94). Large versions can be built in
  stages, one commit per stage.
- **Every commit an agent makes says which agent made it**, with a co-author trailer at the end of
  the message, after a blank line. A local agent commits under the owner's git name and email, so
  without the trailer its work looks like the owner's own.
  - Claude Code: `Co-Authored-By: Claude <model> <noreply@anthropic.com>`, plus the `Claude-Session:`
    line its session asks for.
  - Codex: `Co-authored-by: Codex <noreply@openai.com>`. Add it yourself even when Codex's
    `commit_attribution` setting is on, since Codex applies it through the prompt, not a git hook.
  - Any other agent: `Co-Authored-By: <agent name> <its vendor's noreply address>`.
  - Commits the owner makes by hand get no trailer. Never rewrite pushed commits to add one.
- **PR comments are public.** Report counts, results and repo-relative paths only; no PIDs,
  hardware or kernel details, auth status, or home-directory paths.
- **Checks before every push** (CI runs the same in `.github/workflows/lint.yml`):
  - `bash -n` on each script
  - `shellcheck -S error dev-*.sh` at the repo root (warnings are left for comments to explain;
    `reference/` is not linted)
  - no secrets (gitleaks runs in CI; `.gitleaks.toml` has the two known false positives)
  - no tracked symlinks
  - once `dev-host-wsl.ps1` exists: a PowerShell parse check and PSScriptAnalyzer at Error severity
- **A version isn't done until its test run in WSL on a laptop is clean** (FAIL 0; WARNs only for
  optional credentials). Until then, describe it as "built, not yet confirmed run in WSL".
- **Release:** after a clean run, merge, delete the merged branch, tag `vNN`, and publish a GitHub
  Release with the changelog entry. Fixes found during a version's own testing can be kept in that
  version if the owner says so.
- The scripts will be large (the Chromebook originals at v101: setup ~13,400 lines, demo ~11,900, test
  ~7,800). Make targeted edits; never regenerate a whole script.

## Known open items

Decisions for v1 are recorded: open questions 1–7 and 13 were settled on 2026-11-11. Next comes the WSL review of v77–v101, then the v1 plan; the scripts start after the v1 plan.

Still open: Q8 (Tailscale and LAN sharing; lean: Tailscale on the Windows host, decided when a version
ports install-lan) and the step 3 review (WSL review of v77–v101), both in `docs/plans/wsl-plan.md`.
Nothing there is decided until the owner says so and it is recorded in that doc's Decisions table and
discussion log.
