# WSL Dev Setup Planning

2026-11-11 · Damien · seeded from the dev-setup-windows-wsl handoff and dev-setup-windows'
`docs/plans/windows-plan.md`

> **Where this came from.** Sections marked *(handoff)* come from "dev-setup-windows-wsl — project
> handoff" (prepared 2026-11-11 in the dev-setup-chromebook project space), sections 2–5 and 8. Sections
> marked *(windows-plan)* are imported from
> [dhouse109/dev-setup-windows](https://github.com/dhouse109/dev-setup-windows)'
> `docs/plans/windows-plan.md` (last substantive edit 2026-10-25, written against Chromebook v81 with a
> v82–v93 addendum). Imported text is kept as written; notes added while importing are in *italics* or
> marked "Note (2026-11-11)". The owner's decisions from the PR #1 review (2026-11-11) are in "Decisions
> so far" and ticked in "Open questions"; Q8 stays open.

## Purpose and status

This doc collects every decision and finding about the WSL bundle, so work can start from here instead of
from chat history. Add to the discussion log at the end whenever the bundle comes up, and promote settled
items into Decisions.

**What the bundle is:** a fork of the Chromebook dev bundle that turns **Debian 13 (trixie) on WSL2** on
Damien's Windows laptops into the same development machine the Chromebooks are: same flags, same four
scripts (setup, test, init, demo), same conventions. Most tools install inside WSL as Linux tools, just as
on a Chromebook. A Windows-host PowerShell script, `dev-host-wsl.ps1`, is planned for what has no
Chromebook counterpart.

**Status (2026-11-11): nothing is built.** The repo holds this plan, the rules (`AGENTS.md`), lint CI, an
MIT `LICENSE`, and a read-only copy of Chromebook v101 in `reference/dev-setup-chromebook/` (the source the
fork is made from, minus its `CLAUDE.md`).

**Decisions for v1 are recorded: open questions 1–7 and 13 were settled on 2026-11-11. Next comes the WSL review of v77–v101, then the v1 plan; the scripts start after the v1 plan.**

## How this repo relates to the other two *(handoff)*

| Repo | Approach | Status |
| --- | --- | --- |
| [dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) | Bash bundle for ChromeOS Linux (Debian 13) | v101 released; v102 in progress |
| [dev-setup-windows](https://github.com/dhouse109/dev-setup-windows) | Mostly **native** Windows tools (winget, PowerShell) | Separate project; went that way after the Sep 2026 WSL idea |
| dev-setup-windows-wsl | Debian 13 in WSL2, mirroring the Chromebook bundle | This project; starting now |

dev-setup-windows-wsl revives the original Sep 25–27 2026 plan, which was set aside when dev-setup-windows
went native.

- **Fork source:** dev-setup-chromebook at tag `v101` (commit `68113ff`), copied into
  `reference/dev-setup-chromebook/`. Its `CHANGELOG.md` is authoritative for what each Chromebook
  version added.
- **Fixes travel by hand.** Neither bundle gets platform branches for the other; each release note says
  whether a change ports to the other bundle.
- *Note (2026-11-11): dev-setup-windows' `main` (as of this import) still describes the WSL architecture
  in its `CLAUDE.md` and plan doc; the move to native tools is recorded in the handoff, not yet in that
  repo.*

## Decisions so far

| Date | Decision | Source |
| --- | --- | --- |
| 2026-11-11 | **Separate repo**, dev-setup-windows-wsl, forked from the Chromebook bundle at tag v101. | Handoff (project premise) |
| 2026-11-11 | **Debian 13 on WSL**, not Ubuntu, so it matches the Chromebooks' container. This removes most of the "breaks the run" items from the compatibility review (Docker and Microsoft repo paths, t64 package names). | Handoff §2 (listed there with the Sep 25–27 decisions; windows-plan.md still had Ubuntu or Debian open, so dated here as settled by this project's premise) |
| 2026-09-25 | **Separate bundle, not a platform-aware Chromebook bundle.** The Chromebook scripts never get WSL branches (its AGENTS.md rule 10 says the same). Each repo reads straight through. | windows-plan.md; handoff §2 |
| 2026-09-25 | **Keep the fork diffable:** same flag names, section order and section headings as the Chromebook scripts, so `diff -u` between the two setup scripts shows only real platform differences. *Confirmed 2026-11-11.* | windows-plan.md ("Keeping drift down"); handoff §2 |
| 2026-09-25 | **Tag release notes with portability** ("ports to the other bundle: yes / no / n.a.") so platform-neutral fixes get applied to both. *Confirmed 2026-11-11.* | windows-plan.md; handoff §2 |
| 2026-09-25 | **A shared `dev-common.sh` only later**, and only if porting fixes becomes a chore (it would touch the Chromebook bundle). *Confirmed 2026-11-11.* | windows-plan.md; handoff §2 |
| 2026-09-25 | **A Windows-host script** (proposed `dev-host-windows.ps1`) for what has no Chromebook counterpart; it runs first, then hands off to the bash scripts inside WSL. Scope below. Named `dev-host-wsl.ps1` on 2026-11-11 (Q2). | windows-plan.md; handoff §2 |
| 2026-11-11 | **Windows version:** Windows 11 22H2 or later on all four laptops, stated as the minimum because mirrored networking needs it. | PR #1 review (chat) |
| 2026-11-11 | **Inherited comments:** The fork keeps the Chromebook scripts' tagged comments. A Crostini comment goes only when the code it explains changes or is removed; its replacement is tagged `v1:` with the WSL reason. Supersedes the imported line "the Crostini history in comments can go" (Bundle approach). | PR #1 review (chat) |
| 2026-11-11 | **reference/:** Holds the v101 copy minus `CLAUDE.md`: its `@AGENTS.md` import would load the Chromebook rules into any Claude Code session that reads files under `reference/`. An owner-approved exception to the read-only rule. | PR #1 review (chat) |
| 2026-11-11 | **License:** MIT at the root, as in the Chromebook repo. | PR #1 review (chat) |
| 2026-11-11 | **Q1 Version numbering:** Start at v1. The changelog and `reference/README.md` record "based on Chromebook v101". | PR #1 review (chat) |
| 2026-11-11 | **Q2 Script names:** `dev-setup-wsl.sh`, `dev-init-wsl.sh`, `dev-test-wsl.sh`, `dev-demo-wsl.sh`, and the host script `dev-host-wsl.ps1`. `dev-host-wsl.ps1` replaces the proposed `dev-host-windows.ps1`; `-wsl` avoids clashing with dev-setup-windows' native scripts on the same laptop. | PR #1 review (chat) |
| 2026-11-11 | **Q3 Version rule:** The host script is part of it: five scripts, one version. CHANGELOG gets a host section. | PR #1 review (chat) |
| 2026-11-11 | **Q4 Docker:** docker-ce inside WSL. Preflight stops if Docker Desktop's WSL integration is on for this distro. | PR #1 review (chat) |
| 2026-11-11 | **Q5 Ollama:** Inside WSL for v1 (CUDA on d1, CPU elsewhere). Native Windows Ollama on d3 comes later, after benchmarking, as an option that points `OLLAMA_HOST` at the host. | PR #1 review (chat) |
| 2026-11-11 | **Q6 Editors:** WSLg Linux apps in v1 for all four editors (straight port). Windows-side VS Code, Cursor and Devin with WSL remote come later through the host script. Lazarus stays a WSLg app. | PR #1 review (chat) |
| 2026-11-11 | **Q7 sudo:** NOPASSWD drop-in in `/etc/sudoers.d/`, validated with `visudo -c`. The account keeps its password and `passwd -d` is dropped. The test keeps `sudo -n true`. | PR #1 review (chat) |
| 2026-11-11 | **Q9 Coexistence:** The host script sets `appendWindowsPath=false` in `wsl.conf`. With the docker-ce preflight and distinct script names, both bundles can live on one laptop. Verify that `wslview` works with the Windows PATH off on the first run. | PR #1 review (chat) |
| 2026-11-11 | **Q10 Android:** `install-android-native` is out of v1. `install-mobile` stays, minus the `adb connect arc` steps (the step 3 review confirms this). Later: Studio and the emulator on Windows, with devices reached through the Windows adb server. | PR #1 review (chat) |
| 2026-11-11 | **Q11 Retro and COM:** In WSL for parity, in a later version. | PR #1 review (chat) |
| 2026-11-11 | **Q12 Machines:** First real runs on 109.hpe.d3. Run d4 before calling the bundle done (it has no AVX, and MongoDB 5+ needs AVX); recorded as a per-machine note under Target machines. | PR #1 review (chat) |
| 2026-11-11 | **Q13 v1 scope:** Straight fork of all the code. Flags not yet ported are refused at flag expansion, from one short "not yet supported on WSL" list, and `install-all` skips them with a notice. v1's list: install-lan, install-lan-share, install-android-native, install-retro, install-com. The step 3 review may add to it. | PR #1 review (chat) |
| 2026-11-11 | **Q14 Tiers:** One bundle, no tier mechanism. Flags are chosen per machine, and the docs note d4's limits. | PR #1 review (chat) |
| 2026-11-11 | **Q15 d3 serving models:** Not by default. Decided together with Q5's later option and Q8. | PR #1 review (chat) |
| 2026-11-11 | **Q16 InterBase:** In WSL (ports as-is; opt-in). | PR #1 review (chat) |
| 2026-11-11 | **Q17 DDEV ports:** Keep 8080/8443, as on the Chromebooks. | PR #1 review (chat) |
| 2026-11-11 | **Q18 `.wslconfig`:** The host script sets memory to about 75% of host RAM (24 GB on the 32 GB laptops, 12 GB on the 16 GB ones), adds swap, and enables sparse VHD so freed space returns to Windows. Exact settings are confirmed on the first d3 run. | PR #1 review (chat) |

## Target machines *(windows-plan)*

d3 is the strongest box and the natural home for local models; d4 has the RAM but the weakest CPU.

| Machine | Model | CPU | RAM | Disk | GPU | Likely role |
| --- | --- | --- | --- | --- | --- | --- |
| 109.hpe.d3 | HP Envy 15" | Ryzen 5 5500U (6c/12t) | 32 GB | 1 TB | Radeon iGPU (Vulkan) | Main Windows dev box; LAN model server |
| 109.hpe.d1 | HP Envy 17" | i7-1065G7 | 16 GB | 1 TB | GeForce MX330, 2 GB | Dev box; small CUDA offload |
| 109.hpp.d2 | HP Pavilion 15" | i5-10210U | 16 GB | 1 TB | Intel UHD | Dev box, CPU only |
| 109.hpr.d4 | HP 14" | Pentium Silver N5030 (no AVX/AVX2) | 32 GB | 500 GB | Intel UHD 605 | Light dev; cloud-model client |

All four are x86-64 and run Windows 11 22H2 or later (Decisions, "Windows version"). First real runs are
on d3 (Q12).

**Per-machine notes** (2026-11-11):

- **d4** has no AVX/AVX2, so MongoDB 5+ (which needs AVX) can't run there. d4 gets a run before the
  bundle is called done (Q12); flags are chosen per machine and the docs note d4's limits (Q14).
- *The "LAN model server" role above is the Sep 2026 proposal; d3 does not serve models by default
  (Q15).*

## Bundle approach: separate vs platform-aware *(windows-plan)*

A separate Windows bundle is the chosen route (2026-09-25). It also gives the Windows-host half a natural
home: a PowerShell script (for example `dev-host-windows.ps1`) that runs first, then hands off to the bash
scripts inside WSL.

| Approach | Strengths | Costs |
| --- | --- | --- |
| Separate Windows bundle (chosen) | Chromebook bundle stays untouched after its clean run (PASS 272, FAIL 0); scripts read straight through with no platform branches; Windows choices (host-side editors, `wslview`, sudo policy, D3D12 checks) are first-class; the Crostini history in comments can go; own version numbers and docs | Drift: most code is shared (flag expansion, Homebrew PATH block, nearly every stack), so platform-neutral fixes like v59, v61 and v74 must be applied twice; versioning and companion docs double |
| Platform-aware Chromebook bundle (considered first) | One codebase: a `PLATFORM` / `DISTRO` detection layer plus a preflight, shared by all four scripts | Every change re-verifies the Chromebooks; branches in every script; no place for the Windows-host PowerShell half |

Keeping drift down:

- Fork from the latest Chromebook release, targeting Debian 13 on WSL, so the two bundles stay as close
  as possible. *(Now: v101.)*
- Keep the same flag names, section order and section headings, so `diff -u` between the setup scripts
  shows only real platform differences.
- Tag each future release note with whether it applies to the other bundle (ports to Windows: yes / no /
  n.a.).
- Optionally extract a shared `dev-common.sh` later for sections that never differ; only if porting
  becomes a chore, since it touches the Chromebook bundle.

Every fix in the compatibility review below becomes a straight edit in the fork rather than a platform
branch.

> Note (2026-11-11): "the Crostini history in comments can go" (table above) is superseded. The fork
> keeps the inherited tagged comments; a Crostini comment goes only when the code it explains changes or
> is removed (Decisions, "Inherited comments"). The host script is named `dev-host-wsl.ps1` (Q2).

## Windows-host script scope *(windows-plan, handoff §2; updated 2026-11-11)*

`dev-host-wsl.ps1` covers what has no Chromebook counterpart. It runs first, on Windows, then hands off
to the bash scripts inside WSL:

- enabling WSL and installing the distro
- `wsl.conf`: `[boot] systemd=true`, and `appendWindowsPath=false` (Q9)
- `.wslconfig`: memory at about 75% of host RAM, swap, and sparse VHD (Q18)
- Docker Desktop's WSL integration off (Q4: docker-ce inside WSL)
- usbipd-win
- mkcert trust on Windows
- later version: Windows-side VS Code, Cursor and Devin with their WSL remote extensions (Q6)

## Porting map *(windows-plan)*

> Note (2026-11-11): a first pass from the v77 flag list, updated for v80; it predates the Debian choice
> and the native/WSL split between the two Windows repos. The "Where on Windows" column is the Sep 2026
> proposal. The 2026-11-11 decisions supersede it for Docker (Q4: docker-ce inside WSL), editors (Q6:
> WSLg apps in v1), Ollama (Q5: inside WSL in v1), Android (Q10) and InterBase (Q16: in WSL); the table
> is left as imported. Flags added after v80 are listed under "Not yet reviewed".

Most flags port to WSL almost unchanged; the work concentrates in GPU, GUI apps, Docker and Android. This
map is a first pass from the v77 flag list, updated for v80 (install-interbase, install-ollama-containers,
Firebird in install-db; v78, v79 and v81 added no flags). It is not a settled design.

| Chromebook flag(s) | Where on Windows | What changes |
| --- | --- | --- |
| base section (apt, pipx/uv, SSH key, Homebrew, Chrome) | WSL | Ubuntu vs Debian package names *(n/a under Debian 13)*; ChromeOS-specific steps (`passwd -d`, video/render groups) drop out |
| Docker (base) | Open: Docker Desktop with WSL integration, or Docker Engine inside WSL | Decides how kind, DDEV and Langfuse compose run |
| install-languages (rust, node, go, pwsh, ruby, cpp, asm, dotnet, java) | WSL | PowerShell and .NET also exist natively on Windows; decide whether WSL copies are still wanted |
| install-editors (vscode, windsurf, cursor, lazarus) | Windows host | Native installers (winget); VS Code attaches to WSL via Remote-WSL instead of a Linux install *(superseded: Q6)* |
| install-ollama, install-gemma, install-models | Windows host (Ollama); WSL (Python clients, gemma launcher) | Ollama tuning via user env vars; WSL clients use localhost *(superseded: Q5)* |
| install-ollama-containers (v80) | Windows host (Ollama's listen address) | The systemd drop-in becomes OLLAMA_HOST=0.0.0.0:11434 as a Windows user env var, which d3's LAN role needs anyway. With Docker Desktop, host.docker.internal is the Windows host, so DDEV's drupal-rag demo reaches native Ollama; with Docker Engine inside WSL that name points at the WSL VM, so the route depends on the Docker decision |
| install-interbase (v80, opt-in) | Open: Windows host (native InterBase) vs WSL (the same Linux installer) | In WSL it ports as-is (/opt/interbase, ib-* wrappers, init's console registration). On the host, registration and the server move to Windows, WSL clients connect over TCP on port 3050, and the ib-* wrappers and init step drop out |
| install-agentic, install-lakehouse, install-db, install-db-extra | WSL | Little change; RAM notes relax on the 16-32 GB machines. Since v80 install-db includes Firebird 4 from Debian packages (firebird4.0-*, firebird-utils), whose Ubuntu names are unchecked *(n/a under Debian 13)* |
| install-cloud, install-iac, Ansible, install-k8s | WSL | Little change; kind needs the Docker decision above |
| install-web, install-tanstack, install-drupal, install-vercel, install-jev | WSL | Little change; DDEV depends on the Docker decision |
| install-mobile, install-android-native | Open: Android Studio on Windows (emulator works there) vs WSL | Crostini's `adb connect arc` path has no Windows equivalent |
| install-godot | Windows host | Native Godot gets the real GPU (Vulkan), unlike Crostini's virgl OpenGL |
| install-antigravity, install-media | Windows host | Native installers |
| install-asm-arm | WSL | Unchanged |

The four-script bundle (setup / test / init / demo), shared flags, the versioning rule, the `assets/`
folder and optional-by-default tokens in `secrets.env` all carry over as conventions.

## Compatibility review of the Chromebook bundle under WSL (v76)

*(windows-plan. Added 2026-11-11: the Status column, and the Docker Desktop row, which windows-plan had
as a sentence after the table and the handoff §3 has as a row)*

On Debian 13 in WSL2 most of v76 runs as-is; on Ubuntu, setup aborts early because several steps hardcode
Debian repo paths and package names under `set -e`. Reviewed against v76 on 2026-09-25; v77 only added
the Ollama and model flags. v78 to v81 were not re-reviewed; the likely new Ubuntu gap is v80's Firebird
packages in install-db. All four laptops are x86-64, so the hardcoded `amd64` downloads are fine.

With Debian 13 chosen, the four Ubuntu-only rows no longer apply; they are kept, marked "n/a (Ubuntu
only)" in the Status column, so the review stays complete.

| Impact | Area | Problem under WSL | Fix in the WSL bundle | Status under Debian 13 |
| --- | --- | --- | --- | --- |
| Breaks the run | Docker repo (Ubuntu) | Source line is `linux/debian $(lsb_release -cs)`; an Ubuntu codename under the Debian path fails `apt update` | Pick the repo path from `/etc/os-release` | n/a (Ubuntu only) |
| Breaks the run | Microsoft prod repo (Ubuntu) | `config/debian/${VERSION_ID}` becomes `debian/24.04` and 404s, so install-dotnet and install-db fail; Ubuntu also packages .NET itself | Per-distro repo path; pin .NET to one source; align the test's `packages-microsoft-prod` checks | n/a (Ubuntu only) |
| Breaks the run | Base apt list (Ubuntu) | `libasound2` and `libappindicator3-1` have no candidate on 24.04+; `libfuse2` may need `libfuse2t64` by name; one miss kills the whole install | Distro package map for the t64 and Ayatana names | n/a (Ubuntu only) |
| Breaks the run | systemd (Debian on WSL) | Docker, kind, Langfuse and the Ollama drop-in need it; Ubuntu's WSL image enables it, Debian's likely does not | Preflight check; `[boot] systemd=true` in `/etc/wsl.conf`, then `wsl --shutdown` | Applies; the host script sets it (host-script scope) |
| Wrong for Windows | `sudo passwd -d $USER` | Removes the Linux account's password on a Windows laptop; the test expects `sudo -n true` | Choose a sudo policy (NOPASSWD drop-in, or keep the password) and align the test | Applies; decided: NOPASSWD drop-in, password kept, `passwd -d` dropped (Q7) |
| Wrong for Windows | GPU | WSLg uses `/dev/dxg` and Mesa D3D12: no virgl, no `renderD128`, no sommelier, so those test checks fail even when accelerated | Skip the video/render groups; test accepts D3D12 and fails only on llvmpipe; Godot keeps `opengl3` | Applies |
| Wrong for Windows | Android | The `-cros.deb` Studio build and `adb connect arc` (setup, test, init) are ChromeOS-only; the emulator needs nested virtualization for `/dev/kvm` | Generic Linux tarball or Studio on Windows; devices via usbipd-win or the Windows adb server | Applies; decided: install-android-native out of v1, install-mobile minus `adb connect arc` (Q10) |
| Wrong for Windows | Browser opening | `demo_open` falls back to `xdg-open`, which opens Linux Chrome in WSLg; init's gh, codex and gcloud logins do the same | Install `wslu`; `demo_open` and `BROWSER` use `wslview` | Applies |
| Wrong for Windows | Editors and launchers | VS Code, Cursor and Windsurf install as Linux GUI apps; `.desktop` entries appear in the Windows Start menu via WSLg | Windows-side editors attached through their WSL remote extension; reword the launcher text | Applies; decided: WSLg Linux apps in v1, Windows-side editors later through the host script (Q6) |
| Wrong for Windows | mkcert | CA trusted in Linux only, so a Windows browser warns on DDEV sites | Windows-side trust step, printed as instructions | Applies |
| Wrong for Windows | Messages and hints | "Shut down Linux (right-click Terminal)", balloon notes, the `@chromebook` SSH key comment | `wsl --terminate <distro>` or `wsl --shutdown`; drop the Crostini notes | Applies |
| WSL hazard | Windows PATH interop | Windows `npm` and `code` shims can satisfy `command -v` checks when the Linux tool is missing | `appendWindowsPath=false` in `wsl.conf`, or a preflight warning | Applies; decided: the host script sets `appendWindowsPath=false` (Q9) |
| WSL hazard | Bundle location | Running from `/mnt/c` puts `assets/` on the Windows filesystem: slow, and setuid `chrome-sandbox`, exec bits, pipx and venv paths break | Preflight refuses `/mnt/*`; keep the bundle inside the Linux home | Applies |
| WSL hazard | Line endings | Scripts passed through Windows Git or an editor get CRLF: `$'\r': command not found` | Preflight check for CRLF | Applies; `.gitattributes` (forcing LF) added 2026-11-11 |
| WSL hazard | Resources | WSL caps memory at 50% of host RAM; inotify watches may fall under the test's 30000 | Size memory in `.wslconfig`; `sysctl` for inotify | Applies; memory and swap sized by the host script (Q18) |
| WSL hazard | Docker Desktop | Its WSL integration conflicts with docker-ce | Preflight stops if active | Applies; decided: docker-ce inside WSL; preflight stops if the integration is on for this distro (Q4) |
| WSL hazard | Ubuntu 25.10+ | sudo-rs and Rust coreutils replace sudo and GNU coreutils; the scripts rely on `timeout -k`, `stat -c`, `readlink -f`, `setsid -w` | Confirm on a full test run | n/a (Ubuntu only) |

**Preflight** to add at the top of setup *(handoff §3)*: CRLF, running from `/mnt/*`, systemd not running,
Windows PATH appended, Docker Desktop WSL integration active.

**Host guard** *(handoff §3)*: the Chromebook scripts exit on anything that isn't ChromeOS + Debian; this
fork's guard checks for WSL (`$WSL_DISTRO_NAME` or `/proc/sys/fs/binfmt_misc/WSLInterop`) + Debian.

## Not yet reviewed: v77–v101 *(handoff §4)*

The review above covered v76. v77–v101 have not been checked against WSL. The Chromebook `CHANGELOG.md`
(in `reference/dev-setup-chromebook/`) is authoritative.

**Flags added v77–v93:**

- install-ollama / install-models *(v77; also install-gemma, and install-ollama-containers in v80; in
  the porting map but not the compatibility review)*
- install-db-server (mssql, oracle, interbase) and install-oracle-full; install-ldap
  *(windows-plan: `install-ldap-full` too)*
- `devsvc` services: install-cache, install-search, install-vector, install-mongodb and opt-ins
  *(windows-plan: Redis, Memcached; Solr, OpenSearch, Meilisearch, Typesense; Qdrant, sqlite-vec; opt-in
  `install-elasticsearch`, `install-milvus`, `install-mongodb-atlas-local`)*
- install-laravel, install-symfony, install-graphql, install-vue
- install-cloudflare *(windows-plan: wrangler; opt-in `install-cloudflared`)*
- install-testing, install-gitlab *(windows-plan: `install-playwright`, `install-selenium`,
  `install-bdd`, `install-robot`, opt-in `install-cypress`; glab, gitlab-ci-local, opt-in
  `install-gitlab-runner`)*
- install-puppet / install-chef *(windows-plan: and `install-config-mgmt`)*
- install-lan / install-lan-share (now over Tailscale) *(not in v1: Q13)*
- install-retro and install-com *(not in v1: Q11, Q13)*
- install-hermes / install-openclaw
- *(windows-plan: opt-in `install-godot-templates`)*

**v94–v101:** Lazarus as a Qt5 IDE with light/dark profiles and `lazmode`; herdr and tmux; fpc cthreads in
`~/.fpc.cfg`; Lazarus/Delphi build and debug from VS Code, Cursor and Devin; Devin Desktop under
install-windsurf; Linux links open in ChromeOS's browser; DDEV router on 8080/8443; `devmem`,
`devclean`; DuckDB pinned to 1.5.6; setup stage markers and exit report; output logs in `assets/logs/`;
retro work (win95/winnt40/win2000, exchange disk, DOSBox-X host key, Delphi colors); NuGet IPv6
workaround; `CLAUDE.md` as an `@AGENTS.md` import instead of a symlink.

**Items most likely to behave differently under WSL:**

- **Host guard and "where you are running" rules** in AGENTS.md: rewritten for WSL.
- **Browser standard**: ChromeOS's `garcon_host_browser.desktop` becomes `wslview` (Windows default
  browser).
- **DDEV ports**: 8080/8443 was a ChromeOS workaround (no 80/443 into Linux). WSL can likely use 80/443;
  keep 8080/8443 for parity with install-lan-share, or not. *Decided: keep 8080/8443 (Q17).*
- **Tailscale**: inside WSL (as on the Chromebooks) or on the Windows host with mirrored networking.
  *Open (Q8); lean: Windows host.*
- **install-retro**: QEMU with KVM needs nested virtualization inside WSL2; DOSBox-X and Wine run through
  WSLg. Native Windows options exist but break parity. *Decided: in WSL, later version (Q11).*
- **Crostini-specific fixes** (Devin `--ozone-platform=x11`, Lazarus GTK2 dialog freeze, Android Studio
  XToolkit, memory balloon notes): check whether each still applies under WSLg rather than port blindly.
- **Disk**: space freed inside WSL does not return to Windows until the VHDX is compacted (or sparse VHD
  is enabled), which matters for `devclean` and the disk report. *The host script enables sparse VHD
  (Q18).*
- **NuGet IPv6**: the eldrid-specific workaround may or may not be needed.

## Local models on Windows *(windows-plan; needs revisit)*

> **Needs revisit (2026-11-11).** Written 2026-09-27 assuming Ollama runs natively on Windows, and before
> LAN sharing moved to Tailscale. Q5 puts Ollama inside WSL for v1 (CUDA on d1, CPU elsewhere), with
> native Ollama on d3 a later option after benchmarking; Q15: d3 does not serve models by default. Sizes
> and tags are as of 2026-09-27.

d3's 32 GB makes it the one Windows laptop that runs 14B-class models comfortably; the other three stay at
8B or below. Sizes are Ollama's Q4 downloads as of 2026-09-27; nothing here has been benchmarked on these
machines yet.

| Machine | Acceleration | Comfortable | Stretch |
| --- | --- | --- | --- |
| d3 | CPU + Radeon iGPU via Vulkan | `deepseek-r1:8b` / `14b` (5.2 / 9.0 GB), `qwen3.5:9b` (6.6 GB), `gemma4:12b-it-qat` (7.2 GB) | `gemma4:26b-a4b-it-qat` (16 GB, MoE, ~4B active); `deepseek-r1:32b` (20 GB) fits but crawls |
| d1 | MX330 (Pascal, driver 570+), 2 GB VRAM | Up to `deepseek-r1:8b` | `gemma4:12b-it-qat` |
| d2 | CPU only | Up to 7-8B | none |
| d4 | CPU only, no AVX/AVX2 | 1-2B | none; better as a cloud-model client |

- **DeepSeek:** only the R1 distills run locally. V4-Pro and V4.1-Flash (~760B) are Ollama `:cloud`
  tags, billed per token after `ollama signin`; V4.1-Flash is $0.30 in / $1.20 out per million tokens,
  half off-peak.
- **Vulkan check:** Ollama for Windows enables Vulkan by default; compare against CPU with
  `OLLAMA_VULKAN=0`, since a shared-memory iGPU doesn't always win.
- **Carry over from Chromebook v77:** the server tuning (`OLLAMA_MAX_LOADED_MODELS`,
  `OLLAMA_NUM_PARALLEL`, `OLLAMA_CONTEXT_LENGTH`, flash attention, q8_0 KV cache), set as Windows user
  environment variables instead of a systemd drop-in, with values sized per machine.
- **d3 as LAN server:** `OLLAMA_HOST=0.0.0.0:11434` plus a firewall rule scoped to the private network;
  the Chromebooks' `OLLAMA_REMOTE` in `secrets.env` points at it.
- **On WSL** (from windows-plan's Architecture section): NVIDIA CUDA passes through to Linux, but Intel
  and AMD iGPUs have no practical Vulkan path, which is why native Ollama was proposed.

To fill the table with real numbers once d3 serves models: from a Chromebook,
`~/dev-demo/models/run-compare.sh remote` (Chromebook bundle v77) sends one prompt to every model on
`OLLAMA_REMOTE`'s server and prints load time and tokens per second per model. Run it without `remote`
for the Chromebook's own figures.

Sources: [Ollama DeepSeek models](https://ollama.com/search?q=deepseek) ·
[deepseek-r1 tags](https://ollama.com/library/deepseek-r1/tags) ·
[gemma4 tags](https://ollama.com/library/gemma4/tags) · [qwen3.5 tags](https://ollama.com/library/qwen3.5/tags) ·
[Ollama pricing](https://ollama.com/pricing) · [Ollama hardware support](https://docs.ollama.com/gpu)

## Laptop network *(windows-plan, written for Chromebook v84; needs revisit)*

> **Needs revisit (2026-11-11).** This section predates two changes on the Chromebook side: **LAN sharing
> now runs over Tailscale** (since 2026-10-05; `install-lan` / `install-lan-share` rebuilt on it in v93,
> `tailscaled` in normal tun mode, `LAN_SHARE` as the single list of shared services), so the Windows
> laptops would join the same tailnet rather than rely on mirrored networking and LAN firewall rules
> alone; and **the MCP sharing port is 8770** (since v89), not 8000 as the table says. Where Tailscale
> runs is open question 8 (lean: Windows host with mirrored networking). Decided 2026-11-11:
> install-lan and install-lan-share are not in v1 (Q13); DDEV keeps 8080/8443 (Q17); the Ollama row's
> native Ollama is a later option (Q5).

The Chromebook bundle's v84 adds `install-lan` (an address book, `LAN_HOSTS`, written into /etc/hosts,
and a `lan` command) and `install-lan-share` (a relay that shares a Chromebook's services). The Windows
bundle should serve on the same ports, so `lan scan` on a Chromebook finds the Windows laptops' services
without extra settings.

| Service | Port on the network | Windows side to plan |
| --- | --- | --- |
| Ollama | 11434 | Native Ollama with `OLLAMA_HOST=0.0.0.0:11434`, plus an inbound firewall rule on the Private profile |
| SQL Server | 1433 | Container published on 0.0.0.0, or native SQL Server with TCP/IP enabled |
| Oracle Free | 1521 | Container published on 0.0.0.0 (service FREEPDB1) |
| lldap / OpenLDAP | 3890 and 17170 / 1389 | The same ports; OpenLDAP moved off 389 as on the Chromebooks |
| DDEV sites | 8080 and 8443 | DDEV in WSL with `router_bind_all_interfaces` and router ports 8080/8443, or a relay as on the Chromebooks |
| Dev and MCP servers | 3000, 4200, 5173 / 8000 *(MCP is 8770 since Chromebook v89)* | Started with --host / 0.0.0.0, as on the Chromebooks |

WSL needs mirrored networking (`networkingMode=mirrored` in `.wslconfig`) so its services answer on the
laptop's own address, and inbound rules in both Windows Defender Firewall and the Hyper-V firewall that
governs WSL. The Wi-Fi network must be set to Private. Windows-native apps take laptop names from
`C:\Windows\System32\drivers\etc\hosts`, the counterpart of `lan hosts apply`; the `lan` command itself
runs unchanged inside WSL.

## Open questions

Settled by this project's premise: Debian 13, separate repo, fork from the Chromebook bundle.
*(handoff §5, questions 1–13, wording kept; decisions from the PR #1 review, 2026-11-11, ticked)*

Decisions for v1 are recorded: open questions 1–7 and 13 were settled on 2026-11-11. Next comes the WSL review of v77–v101, then the v1 plan; the scripts start after the v1 plan.

- [x] **1. Version numbering.** Start at v1 with "based on Chromebook v101" recorded, or carry Chromebook
  numbers. v1 avoids implying the two move in lockstep. *Decided 2026-11-11: Decisions, "Q1 Version numbering".*
- [x] **2. Script names.** e.g. `dev-setup-wsl.sh`, `dev-test-wsl.sh`, `dev-init-wsl.sh`,
  `dev-demo-wsl.sh` *Decided 2026-11-11: Decisions, "Q2 Script names".*
- [x] **3. Is the host PowerShell script part of the bundle's version rule?** If yes, five scripts share
  one version. *Decided 2026-11-11: Decisions, "Q3 Version rule".*
- [x] **4. Docker.** docker-ce inside WSL (parity, the old plan's lean) vs Docker Desktop. *Decided 2026-11-11: Decisions, "Q4 Docker".*
- [x] **5. Ollama.** Native on Windows (Vulkan on Intel/AMD iGPUs; proposed Sep 27) vs inside WSL
  (parity; CUDA passes through on d1 only). *Decided 2026-11-11: Decisions, "Q5 Ollama".*
- [x] **6. Editors.** WSLg Linux apps (parity) vs Windows-side editors + WSL remote extensions. *Decided 2026-11-11: Decisions, "Q6 Editors".*
- [x] **7. sudo policy.** NOPASSWD drop-in vs keep the password. *Decided 2026-11-11: Decisions, "Q7 sudo".*
- [ ] **8. Tailscale and LAN sharing.** In WSL vs Windows host + mirrored networking. *Lean (2026-11-11):
  Tailscale on the Windows host with mirrored networking, giving one tailnet node per laptop, while `lan`
  and `LAN_HOSTS` stay in WSL. Decided when a version ports install-lan.*
- [x] **9. Coexistence with native dev-setup-windows on the same laptop.** PATH interop
  (`appendWindowsPath=false`), Docker Desktop vs docker-ce, duplicate Ollama/editors. *Decided 2026-11-11: Decisions, "Q9 Coexistence".*
- [x] **10. Android.** Studio on Windows, generic Linux build in WSL, or out of scope at first. *Decided 2026-11-11: Decisions, "Q10 Android".*
- [x] **11. install-retro and install-com.** In WSL for parity, later version, or native. *Decided 2026-11-11: Decisions, "Q11 Retro and COM".*
- [x] **12. Machines.** First real runs on 109.hpe.d3 (Ryzen 5 5500U, 32 GB)? A WSL distro is cheap to
  reset (`wsl --unregister`), so one laptop can play dragonair's quick-test role. *Decided 2026-11-11: Decisions, "Q12 Machines".*
- [x] **13. First version's scope.** Port everything at once, or base + core stacks first and the rest in
  staged versions. *Decided 2026-11-11: Decisions, "Q13 v1 scope".*

Carried over from windows-plan.md's open questions and not covered above *(wording kept)*:

- [x] **14.** One bundle for all four laptops, or per-machine tiers (d3 heavier models, d4 client-only)? *Decided 2026-11-11: Decisions, "Q14 Tiers".*
- [x] **15.** Should d3 serve models to the Chromebooks by default, and on which network? *Decided 2026-11-11: Decisions, "Q15 d3 serving models".*
- [x] **16.** InterBase (install-interbase): Windows host or WSL? *Decided 2026-11-11: Decisions, "Q16 InterBase".*

Raised in the review and decided with the rest *(2026-11-11)*:

- [x] **17. DDEV ports.** Use 80/443 under WSL, or keep 8080/8443 as on the Chromebooks (see "Not yet
  reviewed")? *Decided 2026-11-11: Decisions, "Q17 DDEV ports".*
- [x] **18. `.wslconfig`.** Memory, swap and disk settings for the WSL VM (see the compatibility review's
  Resources row and the Disk item)? *Decided 2026-11-11: Decisions, "Q18 `.wslconfig`".*

windows-plan.md's other open questions are settled or no longer apply here: Ubuntu or Debian (Debian 13);
the Firebird-on-Ubuntu package names (n/a under Debian); a shared `dev-common.sh` (only later, see
Decisions); the version-history file (the Chromebook convention, `CHANGELOG.md` with a section per script,
carries over); how the Windows-host half is installed (a host script that runs first, see Decisions; its
details follow from questions 2–6).

## Suggested sequence *(handoff §8)*

1. **Seed the repo** (Claude Code, cloud) — prompt in `dev-setup-windows-wsl-kickoff-prompt.md`:
   reference copy of v101, adapted AGENTS.md + CLAUDE.md, imported plan doc, `.gitattributes`, lint CI.
   Draft PR, reviewed in chat, merged by Damien.
2. **Settle the open questions** in chat (at least 1–7 and 13), recorded in the plan doc. *Done
   2026-11-11 (PR #1 review); Q8 stays open.*
3. **WSL review of v77–v101** (Claude Code, cloud, read-only): extend the compatibility table.
4. **v1 plan** in `docs/plans/v1-plan.md` (or whatever numbering is chosen) on `plan/v1`.
5. **Preliminary build** in the cloud on `release/v1`: fork the four scripts, rename, guard, preflight,
   Debian/WSL edits, host script. Lint-clean, "built, not yet confirmed run".
6. **Local**: install Debian in WSL on the test laptop, clone into the Linux home, run Claude Code there,
   init → setup → init → test, fix and loop until FAIL 0. Then release.

## Discussion log

| Date | Topic | Outcome |
| --- | --- | --- |
| 2026-11-11 | PR #1 review: open questions decided | Q1–Q7 and Q9–Q16 decided, plus two new ones (Q17 DDEV ports, Q18 `.wslconfig`): v1 numbering; `-wsl` script names with `dev-host-wsl.ps1` sharing the version; docker-ce in WSL; Ollama in WSL for v1; WSLg editors in v1; NOPASSWD sudo drop-in; `appendWindowsPath=false`; install-android-native, install-lan, install-lan-share, install-retro and install-com on v1's "not yet supported on WSL" list; first runs on d3, d4 before done; one bundle, no tiers; InterBase in WSL; DDEV 8080/8443; `.wslconfig` at ~75% RAM with swap and sparse VHD. Also: Windows 11 22H2 minimum, inherited comments kept, `reference/` without `CLAUDE.md`, MIT license; the diffable-fork, portability-tag and `dev-common.sh` rows confirmed. Q8 (Tailscale) stays open with its lean. Next: the v77–v101 review, then the v1 plan |
| 2026-11-11 | Repo seeded (step 1 of the sequence) | Reference copy of Chromebook v101 (`68113ff`), `.gitattributes`, `.gitignore`, `.gitleaks.toml`, lint CI, this plan, `AGENTS.md` / `CLAUDE.md`, README; draft PR for review. No open question decided |
| 2026-11-11 | New project: dev-setup-windows-wsl | Handoff prepared in the dev-setup-chromebook project space; revives the Sep 25–27 WSL plan on Debian 13, forked from Chromebook v101, as a separate repo alongside the native dev-setup-windows |
| 2026-10-25 | *(dev-setup-windows)* windows-plan.md moved into that repo | "What changed since" addendum: Chromebook at v93, LAN sharing over Tailscale, MCP port 8770, v82–v93 flags listed but not reviewed for WSL |
| 2026-09-29 | *(dev-setup-windows)* Laptops reaching each other's services (Chromebook v84) | Home Wi-Fi only (no Tailscale); Chromebook side built in v84 (install-lan, install-lan-share). *Reversed 2026-10-05: now over Tailscale* |
| 2026-09-28 | *(dev-setup-windows)* Chromebook bundle v78 to v81 | Doc brought up to v81: porting map gains install-ollama-containers and install-interbase, install-db notes Firebird 4; three open questions added (Firebird on Ubuntu, InterBase placement, version-history file) |
| 2026-09-27 | *(dev-setup-windows)* Local models across all eight machines, DeepSeek options | Per-machine model table; native Ollama on Windows proposed; d3 as LAN model server proposed; Chromebook v77 adds `OLLAMA_REMOTE` for it |
| 2026-09-27 | *(dev-setup-windows)* Central planning doc | windows-plan.md created |
| 2026-09-25 | *(dev-setup-windows)* Running the bundle on the Windows laptops | WSL with Ubuntu or Debian; a separate Windows bundle rather than a platform-aware Chromebook bundle. The v76 compatibility review and the bundle-approach comparison are in the sections above |
