# v1 WSL review of Chromebook v77–v101

2026-11-11 · step 3 of the suggested sequence in [wsl-plan.md](wsl-plan.md) · read-only review

> **Status: findings for the owner. Nothing here is decided.** Where the review needs a decision it is
> listed as a question in Part C, with a recommendation. The v1 plan (`v1-plan.md`) is written after the
> owner has answered Part C.

## What was reviewed, and how

- **Source:** the read-only copy of dev-setup-chromebook v101 in `reference/dev-setup-chromebook/`
  (commit `68113ff`): the four scripts (setup 13,359 lines, demo 11,898, test 7,756, init 2,568),
  `CHANGELOG.md` and `docs/crostini-gotchas.md`. Nothing under `reference/` was edited or run.
- **Part A** goes through `CHANGELOG.md` version by version, v77 to v101, all four script sections, and
  checks each change against the v101 code it left behind.
- **Part B** is a search of all four scripts, all of v101 and not only v77+, for ChromeOS and Crostini
  dependencies: `cros`, `crostini`, `chromeos`, `chromebook`, `garcon`, `sommelier`,
  `/dev/.cros_milestone`, `/opt/google/cros-containers`, `virgl`, `renderD128`, `/dev/dri`, the
  video/render groups, `passwd -d`, `adb connect`, `100.115.92`, `-cros.deb`, "Shut down Linux",
  `balloon`, `@chromebook`, `penguin`, `DEV_BUNDLE_ANY_HOST`, `DEV_ON_CHROMEOS`, `xdg-open`, `xdg-mime`,
  `BROWSER`, `garcon-url-handler`, `/dev/kvm`, `inotify`, `btrfs`, `wayland`, `ozone`, `llvmpipe`,
  `systemctl`, `host.docker.internal`, `df`, the machine names, and the script names. Every hit was read
  in context. Line numbers are v101's.
- **WSL behaviour** was checked against the sources listed at the end. This session's network could not
  reach `learn.microsoft.com`, `docs.ddev.com` or Debian's package sites, so Microsoft's and DDEV's docs
  were read from their GitHub sources, and Debian package facts could not be checked at all. **Anything
  not confirmed by a source is marked "verify on first run" and is not stated as fact.**

**"Under WSL" values** used in Part A: **as-is** · **WSL edit** (what) · **ChromeOS-only** (drop or
replace) · **verify on first run** (what to check). **"v1 status"**: **in v1** · **on the refused list**
(existing) · **candidate for the refused list**.

## Summary

| | Count |
| --- | --- |
| Part A rows (v77–v101 changes) | 78 |
| Part A: as-is | 39 |
| Part A: as-is, with a first-run check | 7 |
| Part A: WSL edit | 18 |
| Part A: ChromeOS-only (replace) | 2 |
| Part A: inside a refused flag, not applicable in v1 | 11 |
| Part A: already adopted in this repo | 1 |
| Part B inventory items: setup | 58 |
| Part B inventory items: test | 44 |
| Part B inventory items: init | 23 |
| Part B inventory items: demo | 32 |
| Part B total | 157 |
| New candidates for the "not yet supported on WSL" list | 0 required (a watch list of 5) |
| Flags that need or may need AVX | 1 documented, 5 to verify on d4 |
| New open questions | 16 (Q19–Q34) |
| Items in wsl-plan.md found wrong or stale | 9 |

The headline findings:

1. **`wslu` is not a safe base for opening links.** Upstream is discontinued and archived, Ubuntu 26.04
   no longer ships it, and its tools are reported to look up Windows programs on the PATH that Q9 turns
   off (Q19).
2. **WSLg does not list `~/.local/share/applications` in the Start menu.** It scans four system
   folders only, so the bundle's own launchers (Cursor, Godot, Devin (X11), Lazarus (Dark), Antigravity)
   would not appear, and Devin's hide-the-stock-entry scheme cannot work as built (Q20).
3. **VS Code's `code` command stops and asks a question under WSL** unless `DONT_PROMPT_WSL_INSTALL`
   is set. Without it the test's `code --version` fails and a wrapper started from an icon exits (Q28).
4. **Q17 is an edit, not a no-op.** The DDEV 8080/8443 step and its test check are both inside
   `DEV_ON_CHROMEOS` conditions; outside ChromeOS the code leaves DDEV on 80/443.
5. **Disk guards read the VHDX's virtual size.** `df` inside WSL does not show how full the Windows
   drive is, which matters most on d4's 500 GB disk (Q25).
6. **Q10 is confirmed, with a correction:** install-mobile's `adb connect arc` steps are in init and
   test only; setup mentions it only in install-android-native's closing text.
7. **No flag has to join the refused list.** The existing five cover everything that cannot work.

---

## Part A: what v77–v101 added

One row per flag, stack or behaviour. "Version" is the version that added or last reshaped it. Rows for
refused flags are kept short: their code is forked untouched and reviewed when the flag is ported.

| # | Version | Area / flag | What it does on a Chromebook | Under Debian 13 on WSL2 | Fix in the WSL bundle | v1 status |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | v77 | install-ollama (own flag) | Ollama's installer, a systemd drop-in with six settings sized for 8 GB, `OLLAMA_API_BASE` and `ollama-remote` in `~/.bashrc` | **WSL edit.** The installer detects WSL2, skips GPU driver packages and exits after installing; it sets up the unit only when systemd is running. The drop-in works with systemd on | Reword "CPU-only in Crostini" (setup 7632, test 4459). Keep the six settings (Q30). On d1, check that CUDA is used: Ollama's docs want driver 570+ for older cards | in v1 |
| A2 | v77 | install-models (opt-in) | Pulls three small models, with a free-disk guard | **WSL edit** (message) and see A63 for the guard | Reword "Give Linux more disk (ChromeOS Settings…)" (setup 7998, test 4439) | in v1 |
| A3 | v77 | gemma client options | `-m MODEL`, `--local`, `--think` | **as-is** | none | in v1 |
| A4 | v77 | test: disk report TSV | Per-stack disk usage, file labelled with `MACHINE_LABEL` because every container is called `penguin` | **as-is.** Under WSL the hostname is the Windows computer name, so the fallback is already distinct | Comment only if the code changes. See A63 for what "Linux disk" means | in v1 |
| A5 | v77 | demo: models/local-rag, models/compare | RAG and model comparison demos | **WSL edit** (generated text) | The demo corpus describes "an 8 GB Chromebook" and "CPU-only in Crostini" (demo 2238–2276): rewrite (Q34) | in v1 |
| A6 | v78 | demo: media/sintel source | Clip from archive.org, shown with `demo_open file://…` | **verify on first run:** a `file://` path in the Linux home has to reach the Windows browser as a `\\wsl.localhost\…` path | Opener converts local paths (Q19) | in v1 |
| A7 | v79 | install-lakehouse: Delta Lake | DuckDB delta extension, `deltalake` in the venv | **as-is** | none | in v1 |
| A8 | v80 | install-db: Firebird 4 | Debian packages, embedded engine, lock-directory probe | **as-is** | none | in v1 |
| A9 | v80 | install-interbase (opt-in) | Silent InstallAnywhere install into `/opt/interbase` from the owner's download | **as-is** (Q16). **verify on first run:** the silent installer and `ibmgr` under WSL | none expected | in v1 |
| A10 | v80 | install-ollama-containers (opt-in) | Second drop-in, `OLLAMA_HOST=0.0.0.0:11434`, so containers reach Ollama at `host.docker.internal` | **as-is** with docker-ce. The comment's safety claim (not exposed to the network) should hold under NAT, where WSL ports reach Windows through localhost forwarding. It stops holding under mirrored networking | Note for Q8: revisit when mirrored networking arrives | in v1 |
| A11 | v81 | install-db / install-interbase fixes | `firebird-utils`; unpack into `assets/downloads` | **as-is** | none | in v1 |
| A12 | v82 | install-db-server, install-mssql, install-oracle, `devdb` | SQL Server 2025 and Oracle Free Lite as containers, created stopped; clients; one engine at a time | **as-is** code. **WSL edit** for messages | Reword the disk message (setup 4919, 13297). Comments about "~6.4 GB of an 8 GB Chromebook" stay with their code. AVX on d4: verify (Part C) | in v1 |
| A13 | v83 | install-oracle-full (opt-in) | Oracle's full image in its own volume | **as-is** | none | in v1 |
| A14 | v83 | install-ldap (lldap in Docker), `ldap` command | Container, seed data, `ldap ui` opens the web UI | **WSL edit:** `ldap ui` calls `garcon-url-handler` first (setup 5759–5762) | Use the bundle's opener (Q19) | in v1 |
| A15 | v83 | install-ldap-full (slapd) | Debian's slapd as a systemd service on 389, all interfaces | **as-is** with systemd on. Under NAT it is not reachable from the network; under mirrored networking it would be, subject to the Hyper-V firewall | Note for Q8 | in v1 |
| A16 | v84 | install-lan, install-lan-share, `lan` | Address book in `/etc/hosts`, relay, ChromeOS port forwards | **ChromeOS-only** in part (port forwarding, the relay's purpose) | Ported with Q8 | on the refused list (existing) |
| A17 | v84 | demo: net/mcp-hello | MCP server shared between laptops | n.a. in v1 | with install-lan | on the refused list (existing) |
| A18 | v85 | install-com | Wine, mingw, widl, a COM prefix | n.a. in v1 (Q11) | later version | on the refused list (existing) |
| A19 | v85 | install-retro | DOSBox-X, Open Watcom, `win31` | n.a. in v1 (Q11) | later version | on the refused list (existing) |
| A20 | v86 | install-hermes (opt-in) | Hermes Agent through its own installer | **as-is** code. **WSL edit** for notes | Notes say "the Crostini user has passwordless sudo" (true under Q7; reword) and "the container sleeps with the Chromebook" (setup 13136–13143, 13351; init 543, 2345, 2537) | in v1 |
| A21 | v86 | install-openclaw (opt-in) | npm package on nvm's Node | **as-is** code. **WSL edit** for the same notes as A20 | Same rewording. **verify on first run:** whether a gateway service survives after the last terminal closes (Q33) | in v1 |
| A22 | v87 | install-laravel | Laravel installer through Composer, php-bcmath | **as-is** | none | in v1 |
| A23 | v88 | install-symfony | Symfony CLI .deb, checksum checked | **as-is** | none | in v1 |
| A24 | v89 | `devsvc` and its containers (install-cache, -search, -vector, -mongodb, opt-ins) | Redis, Memcached, Solr, OpenSearch, Elasticsearch, Meilisearch, Typesense, Qdrant, Milvus, MongoDB, Atlas Local on 127.0.0.1, created stopped, memory guard | **as-is** with docker-ce and systemd | none in code. `DEVSVC_RAM_MB` (3000) is sized for 8 GB; it is a setting, left alone | in v1 |
| A25 | v89 | install-mongodb, install-mongodb-atlas-local | MongoDB 8 container; mongosh, tools, Compass | **as-is** on d1–d3, with a **WSL edit** for one message. **Cannot run on d4:** MongoDB 5.0+ needs AVX | Per-machine note (already recorded). Reword "Compass (ChromeOS launcher)" (setup 6791, test 4124, demo 7198) | in v1 |
| A26 | v89 | OpenSearch / Elasticsearch `allow_mmap=false` | Avoids `vm.max_map_count`, which a Crostini container cannot raise | **as-is.** The setting works anywhere; WSL could raise the sysctl but has no need to | none (comment stays with its code) | in v1 |
| A27 | v89 | Redis Insight, MongoDB Compass (GUI .debs) | Desktop apps, "pick it from the ChromeOS launcher" | **WSL edit** (messages). Both install into `/usr/share/applications`, which WSLg lists. **verify on first run:** they start under WSLg | Reword (setup 6049, 6084, 6732, 6791; test 3913, 4124) | in v1 |
| A28 | v89 | sqlite-vec (install-vector) | Loadable extension from the GitHub release | **as-is** on d1–d3. **verify on d4:** the release build enables AVX when its build machine has it | Per-machine note if it crashes on d4 | in v1 |
| A29 | v89 | install-cloudflare, install-cloudflared | wrangler (npm); cloudflared from Cloudflare's apt source | **as-is.** `wrangler login` opens a browser: see A53 | none | in v1 |
| A30 | v89 | install-agentic: FastMCP CLI, MCP Inspector | uv tool and a global npm package | **as-is** | none | in v1 |
| A31 | v89 | LAN_SHARE knows the new services; `LAN_MCP_PORTS` 8770 | Sharing list for install-lan-share | n.a. in v1 | with install-lan | on the refused list (existing) |
| A32 | v89 | demo: services/*, agents/fastmcp, cloud/cloudflare | Search, MongoDB and MCP demos | **as-is** (pages open through `demo_open`) | none beyond A53 | in v1 |
| A33 | v90 | install-graphql | Rover, Router v2, Apollo MCP Server binaries | **as-is** | none | in v1 |
| A34 | v91 | install-playwright | `playwright install --with-deps` (Debian 13 supported), Playwright MCP | **as-is.** **verify on first run:** headed runs and WebKit under WSLg | none | in v1 |
| A35 | v91 | install-selenium | Selenium Grid container (devsvc), Selenium Manager with the system Chrome | **as-is.** noVNC on 7900 opens through `demo_open` | none | in v1 |
| A36 | v91 | install-bdd, install-robot | Reqnroll templates; Robot Framework as a uv tool | **as-is** | none | in v1 |
| A37 | v91 | install-cypress (opt-in) | Cypress's libraries, Xvfb | **as-is.** **verify on first run:** Electron under Xvfb in WSL | none | in v1 |
| A38 | v91 | install-gitlab, install-vue | glab (Homebrew), gitlab-ci-local; npx caches for Vue and Nuxt | **as-is** | none | in v1 |
| A39 | v91 | install-gitlab-runner (opt-in) | GitLab Runner from GitLab's apt source, a systemd service | **as-is** with systemd on | none | in v1 |
| A40 | v91 | install-puppet, install-chef, install-config-mgmt (opt-in) | OpenVox, OpenBolt, Cinc Workstation | **as-is** (`systemctl disable --now puppet` needs systemd) | none | in v1 |
| A41 | v92 | install-retro grows: QEMU, guests, `delphi1`, kvm group | Three engines, exchange disks, snapshots | n.a. in v1 | later version | on the refused list (existing) |
| A42 | v92 | Disk guard `min(10 GB, 15% of the Linux disk)` | Skips an image pull that would fill the disk | **WSL edit:** `df` inside WSL reads the VHDX's virtual size, not the Windows drive's free space | Q25 | in v1 |
| A43 | v92 | InterBase `ib-server`, licence detection | Start, stop, status without the unregistered server | **as-is** | none | in v1 |
| A44 | v92 | test/init: GitHub SSH key checks | Asks GitHub whether it accepts the key | **as-is** | none | in v1 |
| A45 | v93 | Retro: Delphi 3–7, app CDs, exchange-disk sizes, win95 snapshots | New `delphi` command | n.a. in v1 | later version | on the refused list (existing) |
| A46 | v93 | install-lan over Tailscale | Tailscale apt source, `--tun=tailscale0`, `tailscale serve`, `lan probe` | n.a. in v1 (Q8 open) | with Q8 | on the refused list (existing) |
| A47 | v93 | Database fixes (InterBase `ldconfig`, Oracle `setPassword.sh`) | From the Oct 4 run | **as-is** | none | in v1 |
| A48 | v93 | IPv4 preference when IPv6 does not get out | Checks dl.google.com over IPv6 and IPv4; writes `/etc/gai.conf` and an apt setting | **verify on first run:** what the check does under NAT. If WSL resolves IPv6 addresses but has no IPv6 route, it will apply the fix on every laptop | Q27 | in v1 |
| A49 | v93 | 20-second connect timeout for wget and curl; `fetch_checked` | Per-run config files; validated downloads | **as-is** | none | in v1 |
| A50 | v94 | Lazarus on Qt5, `lazmode`, light and dark profiles, qt5ct | Four IDE builds on Qt5 because the GTK2 IDE drew blank dialogs under Crostini | **as-is** (see the verdict below). **WSL edit** for the dark launcher's location and message | Q20 | in v1 |
| A51 | v95 | tmux (base), install-herdr | apt package; herdr's own installer into `~/.local/bin` | **as-is** | none | in v1 |
| A52 | v95 | lazmode: install list, adopting the IDE's own build | Keeps layouts in step with packages | **as-is** | none | in v1 |
| A53 | v96 | Links from Linux open in ChromeOS's browser | `xdg-mime default garcon_host_browser.desktop` for https, http and text/html | **ChromeOS-only.** WSL has no garcon | Replace with a Windows-browser handler (Q19). init's logins (gh, codex, gcloud, aws sso, vercel) and every demo page go through it | in v1 |
| A54 | v96 | DDEV router on 8080/8443 | `ddev config global --router-http-port=8080 --router-https-port=8443`, only when `DEV_ON_CHROMEOS=1` | **WSL edit.** Q17 keeps the ports, but the step and its test check are ChromeOS-conditional | Remove the condition in setup (770–804) and test (1109–1122); reword the reason | in v1 |
| A55 | v96 | mkcert CA import instructions for ChromeOS's browser | Prints the ChromeOS Settings steps | **ChromeOS-only** | Replace with the Windows trust step (host script; Q24) | in v1 |
| A56 | v96 | DDEV telemetry off in base | `ddev config global --instrumentation-opt-in=false`, `DDEV_NO_INSTRUMENTATION` | **as-is** | none | in v1 |
| A57 | v96 | Devin Desktop under X11 (install-windsurf) | Wrapper with `--ozone-platform=x11`, a separate "(X11)" launcher entry, the stock entry hidden | **WSL edit** (see the verdict below) | Keep the wrapper and flag; rework the launcher half (Q20); set `DONT_PROMPT_WSL_INSTALL` (Q28) | in v1 |
| A58 | v96 | `devmem` | Memory report whose residual line is "taken back by ChromeOS (estimate)" | **WSL edit** (see the verdict below) | Q31 | in v1 |
| A59 | v96 | `devclean` | Reports and clears caches; repairs a 0-byte DDEV state file | **WSL edit** (one added note; the command itself is as-is, see the verdict below) | Add a note about sparse VHD and compaction (Q26) | in v1 |
| A60 | v96 | `-dUseCThreads` in `~/.fpc.cfg` | Thread support for every Free Pascal compile | **as-is** (not Crostini-specific, as its own comment says) | none | in v1 |
| A61 | v96 | Lazarus and Delphi projects in VS Code, Cursor and Devin (`lazmode vscode`, gdb, Global, ctags) | Tasks, launch configs, a Debug-gdb build mode | **as-is.** The `delphi N build` and `delphi N vscode` halves belong to install-retro | none | in v1 (retro half refused) |
| A62 | v96 | lazmode: Qt5 as the IDE's own rebuild target; docking option | `ide_target`, `dock_options` | **as-is** | none | in v1 |
| A63 | v97 | devclean additions (editor caches, old extension versions, Chrome profile caches, `--where`, `sync` before `df`) | From the v97 Chromebook runs | **as-is.** `sync` was added for btrfs; on WSL's ext4 it is harmless | none | in v1 |
| A64 | v97 | Screen output saved to `assets/logs/<script>-<date-time>.output` | The script restarts itself inside util-linux `script` | **WSL edit** (one line): the log name is derived by stripping `-chromebook` from the script name (setup 40, test 117) | Strip `-wsl` instead | in v1 |
| A65 | v97 | aider upgraded in place; Lazarus debs and Chrome not downloaded again | Rerun savings | **as-is** | none | in v1 |
| A66 | v98 | DuckDB pinned to 1.5.6; Cursor install record; devclean DDEV images and Chrome shader caches | From the v98 plan | **as-is** | none | in v1 |
| A67 | v98 | Scripts recorded executable in Git (100755) | So a clone runs without `chmod` | **WSL edit** (repo, not script): the forked scripts need the same mode, and `.gitattributes` already keeps them LF | Set the mode when the scripts are forked | in v1 |
| A68 | v99 | pip policy, `net_retry`, `vendor_install`, apt retries | Bounded retries; installers fetched fully before they run | **as-is** | none | in v1 |
| A69 | v99 | Stage markers, EXIT report, `setup-stages.tsv`, rerun line | Says which stages failed or were not reached | **WSL edit** (one line): the rerun line names `dev-setup-chromebook.sh` (setup 426). **verify on first run:** a refused flag stripped from a group is reported as not selected, not as unreached | Rename | in v1 |
| A70 | v99 | Managed Playwright install; random generator; local .debs readable by `_apt` | Fix release | **as-is** | none | in v1 |
| A71 | v99 | Typesense `/proc/self/io` shim | Preloaded only when the kernel lacks that file | **as-is:** it tests for the file itself. **verify on first run:** whether WSL's kernel provides it (the shim then stays off) | none | in v1 |
| A72 | v100 | NuGet and PowerShell Gallery over IPv4 | `DOTNET_SYSTEM_NET_DISABLEIPV6=1` on each dotnet command | **as-is** (see the verdict below) | none | in v1 |
| A73 | v100 | Retro guest changes (Win95, Windows 2000, fonts, colours, DOSBox-X host key, genisoimage) | Owner's findings | n.a. in v1 | later version | on the refused list (existing) |
| A74 | v101 | `CLAUDE.md` as an `@AGENTS.md` import; CI checks for symlinks | Repository change | already adopted here (PR #1) | none | n.a. |
| A75 | v101 | Retro: NT CPU default, PipeWire audio, local LAN for NT/2000 | Owner's findings | n.a. in v1 | later version | on the refused list (existing) |
| A76 | v101 | Inspector diagnostics; devclean explains the npm cache | Wording | **as-is** | none | in v1 |
| A77 | v92–v101 | test and init: `/dev/kvm` and kvm-group reporting | INFO and todo lines inside the retro sections | n.a. in v1. For later: nested virtualization is on by default on Windows 11, so `/dev/kvm` may exist | later version | on the refused list (existing) |
| A78 | v96 | test: editor started from its icon misses PATH (login-shell timing check) | WARN from 5 s, FAIL from 10 s | **as-is.** `appendWindowsPath=false` (Q9) removes the usual WSL cause of a slow shell start | none | in v1 |

### Verdicts on the items most likely to behave differently

Each item from the plan's list, with whether it is still needed under WSLg and why.

**Host guard and "where you are running" rules.** Needed, rewritten. The guard block is identical in all
four scripts (setup 6–27, test 83–104, init 23–44, demo 35–56) and tests three ChromeOS markers. It
becomes WSL (`$WSL_DISTRO_NAME` or `/proc/sys/fs/binfmt_misc/WSLInterop`) plus Debian. It also sets
`DEV_ON_CHROMEOS`, which four lines outside the guards read (setup 639, 779 and 833; test 1112; none
in init or demo), so each of those conditions needs its own decision; they are in Part B (S9, S14,
S15, T12). Whether the WSL
guard keeps a bypass variable is Q22.

**Browser standard (`garcon_host_browser.desktop` → `wslview`).** The mechanism is still needed; the
tool named in the plan is the problem. Linux Chrome is still installed (Selenium Manager, Robot and the
BDD runners use it), so without a handler, links and sign-in pages would open in a Linux Chrome inside
the VM, the same fault v96 fixed. But `wslu`, which provides `wslview`, is discontinued and archived
upstream; DDEV removed it from its Windows installer in April 2026 because Ubuntu 26.04 has no package
for it; and bug reports say wslu's tools look Windows programs up on the PATH, which
`appendWindowsPath=false` empties.
Whether Debian 13 carries the package could not be checked. Recommendation in Q19: a small opener the
bundle owns.

**DDEV ports 8080/8443.** Still wanted (Q17), and it needs code. The step runs only when
`DEV_ON_CHROMEOS=1`; otherwise setup prints "not ChromeOS, so DDEV's router stays on its own ports" and
the test skips its check. Under NAT a Windows browser reaches `https://<site>.ddev.site:8443` because
the name resolves to 127.0.0.1 and WSL forwards localhost ports to the VM (`localhostForwarding`,
default true). **Verify on first run** that a DDEV site opens that way with DDEV's router bound to
127.0.0.1.

**Tailscale.** Not in v1. Q8 stays open. The v93 code contains one Crostini-specific workaround
(`--tun=tailscale0`, because `tailscaled` chose userspace networking in that VM); whether WSL needs it
is a question for the version that ports install-lan.

**install-retro.** Not in v1 (Q11). For the later version: Microsoft documents `nestedVirtualization`
as on by default on Windows 11, so `/dev/kvm` is likely to exist; reports say its owner and mode need
setting on each start, which the v92 "add you to the group that owns `/dev/kvm`" code may or may not
cover. DOSBox-X and Wine would run through WSLg. Nothing to do now.

**Devin `--ozone-platform=x11`.** Keep the wrapper and the flag; rework the launcher half. The Crostini
fault was ChromeOS's Wayland compositor (through sommelier) freezing or closing the window. WSLg's
compositor is Weston, a different one, so that exact fault may not occur. The flag is still the safer
default: it pins the one display path the bundle has seen Devin work on, and it costs nothing if Devin
would have chosen X11 anyway. What cannot carry over is the launcher scheme. It writes
`devin-desktop-x11.desktop` and a `NoDisplay=true` copy of the stock entry into
`~/.local/share/applications`, and WSLg does not read that folder, so the Start menu would show only
the stock entry from `/usr/share/applications`, which runs the Electron binary directly (the path that
crashed within 5 seconds on ChromeOS). **Verify on first run:** whether the stock entry works under
WSLg, and whether `/usr/bin/devin-desktop` asks VS Code's WSL question (Q20, Q28).

**Lazarus GTK2 dialog freeze and the Qt5 rebuild.** Keep the Qt5 rebuild as it is; do not test GTK2.
The blank modal dialogs were seen under Crostini and nobody knows whether WSLg's XWayland shows them.
It does not matter: since v94 the Qt5 IDE is the bundle's Lazarus design, not a patch on top of it.
`lazmode`, the light and dark profiles, qt5ct, the docking handling, v96's `ide_target` and about 300
lines of test checks all assume Qt5. Going back to GTK2 would make the fork diverge for no gain.
**Verify on first run:** Qt5 dialogs take focus under WSLg, the floating layout's separate windows
behave, and qt5ct's dark palette applies. The dark launcher's location is Q20.

**Android Studio XToolkit.** Not needed in v1: install-android-native is refused, so the pin
(setup 4347–4368) and its test check (test 2371–2377) are never reached. The dimming was a ChromeOS
Wayland effect on the JetBrains runtime. Whether it happens under WSLg is unknown, and the later plan
(Q10) puts Studio on Windows, where the pin has no meaning. Decide when Android is ported.

**Memory balloon notes.** The explanation does not apply; most of the code around it does no harm.
crosvm's balloon made `free` show reclaimed memory as "used" and made a cold model load slow. WSL2 has
a fixed ceiling (`memory` in `.wslconfig`) and hands cached memory back to Windows
(`autoMemoryReclaim`, documented default `dropCache`), so `free` is not expected to show reclaimed
memory as used. **Verify on first run** with `devmem`. So: `OLLAMA_LOAD_TIMEOUT=15m` stays (a long
timeout is harmless, and d4's CPU is slow); the
comments stay with their unchanged code (rule 3); the user-facing hints that say "close Chrome tabs and
Android apps on the ChromeOS side" (test 4394, 4457) are reworded for Windows.

**`devmem`'s ChromeOS memory reporting.** The command is still useful; one line of it is not. Top
programs, the bundle's running containers, Ollama's loaded models and the verdict all work unchanged.
The residual line "taken back by ChromeOS (estimate)" (setup 942, 996) and the verdict "ChromeOS has
taken back … close ChromeOS tabs or Android apps" (setup 972) describe the balloon. Under WSL the
residual should be near zero, and what Windows programs use is invisible from inside the VM. The "no
swap" finding will rarely fire, because WSL gives the VM swap by default (25% of Windows memory). The
test parses the label (test 896–909), so the two change together. Wording is Q31.

**`devclean` with sparse VHD.** `devclean` itself is as-is: its figures come from `df` on the Linux
filesystem and are right for what Linux sees. What changes is what the user gets back. Space freed
inside WSL returns to Windows only if the VHDX is sparse, or after it is compacted by hand. Sparse VHD
is an experimental setting, `sparseVhd=true` applies only to newly created disks, an existing distro is
switched with `wsl --manage <distro> --set-sparse true`, and during 2025 that command was blocked
behind `--allow-unsafe` because of a data-corruption risk; later reports say it was re-enabled. So Q18's
"enables sparse VHD so freed space returns to Windows" needs a second look (Q26). The fix on the
bundle's side is one sentence in `devclean --help` and after `--run`.

**NuGet IPv6 workaround.** Keep as-is. It is an environment variable on each `dotnet` command, not a
system change, and it does nothing when IPv6 would not have been used. Keeping it costs nothing and
keeps the diff against the Chromebook scripts empty at 14 call sites (setup 2, test 6, demo 6).

**herdr and tmux.** As-is. tmux is a Debian package and herdr is one binary in `~/.local/bin`; neither
touches anything ChromeOS-specific, and no `~/.tmux.conf` is written. **Verify on first run:** herdr's
key bindings and mouse support in Windows Terminal.

---

## Part B: ChromeOS-specific code inventory (all of v101)

This is the v1 build's worklist. Grouped by script, then by the section heading or stage name as it
appears in the script. "Kind" is one of:

- **replace**: ChromeOS-only code that gets a WSL counterpart
- **drop**: ChromeOS-only code with no counterpart
- **edit**: code that works but needs a change for WSL
- **text**: only a message, label or generated text changes
- **rename**: the script's name or version
- **new**: a block that does not exist yet
- **verify**: no change expected; check on the first run
- **refused**: inside a flag on the refused list; forked untouched (Q32)

### dev-setup-chromebook.sh → dev-setup-wsl.sh (58 items)

| # | Lines | Section | What is there | Kind | WSL change |
| --- | --- | --- | --- | --- | --- |
| S1 | 1–4 | header | `dev-setup-chromebook - Version 101` | rename | `dev-setup-wsl`, Version 1, "based on Chromebook v101" |
| S2 | 6–27 | `>>> dev-bundle host guard >>>` | Three ChromeOS markers, `DEV_ON_CHROMEOS`, the Debian check, the `DEV_BUNDLE_ANY_HOST` offer | replace | WSL2 + Debian guard (Q22) |
| S3 | after 27 | (new) setup preflight | nothing | new | CRLF, running from `/mnt/*`, systemd not running, Windows PATH appended, Docker Desktop integration on; candidates from this review: not root, `sudo -n true`, WSL 2 not 1 (Q29) |
| S4 | 29–97 | `>>> dev-bundle screen output >>>` | `_sn=${_sn%%-chromebook*}` (40) names the log file | edit | strip `-wsl` |
| S5 | 129–360 | `FLAG EXPANSION (STACK SWITCHES)` | No refused list. `install-ecosystems` includes install-android-native (151); install-retro pulls install-com (196–198); install-lan-share pulls install-lan (189–191) | new | Refuse a directly named flag from `DEV_REQUESTED_FLAGS` (131) before anything installs; strip refused members after expansion, with a notice |
| S6 | 362–530 | stage report helpers | Rerun line prints `dev-setup-chromebook.sh` (426); `stage_expect` lines for refused flags (473–474, 524–526) | rename, verify | Rename; check stripped flags report as not selected |
| S7 | 532 | banner | "Starting comprehensive Chromebook Linux provisioning" | text | WSL wording |
| S8 | 548–591 | `stage network` | IPv4 preference check and `/etc/gai.conf` edit | verify | Record what it does under NAT (Q27) |
| S9 | 636–639 | `stage system` | `sudo passwd -d "$USER"` when on ChromeOS | replace | NOPASSWD drop-in in `/etc/sudoers.d/`, checked with `visudo -c`; who writes it is Q21 |
| S10 | 681 | `stage ssh` | Key comment `$USER@chromebook` | edit | A machine name instead (the hostname is the Windows computer name) |
| S11 | 688–694 | `stage docker` | docker-ce from Docker's Debian repository | verify | As-is. Check `dockerd` starts with Debian 13's iptables under the WSL kernel (older Debian-on-WSL2 reports needed `iptables-legacy`) |
| S12 | 695–702 | `stage docker` | Adds the user to `video` and `render` for virgl's `renderD128` | drop | WSLg's GPU is `/dev/dxg`, not a render node. Check its permissions on the first run |
| S13 | 768 | `stage homebrew` | `mkcert -install` (Linux trust stores) | verify | As-is; its CA folder depends on Q24 |
| S14 | 770–804 | `stage homebrew` | DDEV router ports, only `if DEV_ON_CHROMEOS` (779–780); messages name ChromeOS (792, 797) | edit | Unconditional (Q17); reword |
| S15 | 830–838 | `stage homebrew` | Prints how to import mkcert's CA into ChromeOS | replace | Windows trust step (Q24) |
| S16 | 840–858 | `stage chrome` | Linux Google Chrome | verify | As-is: the test tools need it. Check it starts under WSLg |
| S17 | 860–882 | `stage chrome` | `xdg-mime default garcon_host_browser.desktop …` | replace | Register the Windows-browser handler (Q19) |
| S18 | 886–901 | `stage devmem` | Header comments describing ChromeOS taking memory back | text | Follows S19 |
| S19 | 942, 972, 974, 996, 1035 | `stage devmem` | `TAKEN`, the "ChromeOS has taken back" verdict, the Linux Chrome verdict, the report line, the closing echo | edit | Relabel the residual; drop or reword the verdict (Q31) |
| S20 | 1142–1145 | `stage devclean` | `sync` before `df`, added for btrfs | verify | As-is |
| S21 | devclean `--help` and `--run` output | `stage devclean` | No mention of the VHDX | new | One note: space returns to Windows with a sparse VHD or after compaction (Q26) |
| S22 | 1754–1759 | `stage shared-helpers` | `disk_margin_gb`, `disk_free_gb` read `df /` | edit | Q25 |
| S23 | 2496–2509 | install-vscode | Installs `code`; nothing about WSL | new | `DONT_PROMPT_WSL_INSTALL` (Q28) |
| S24 | 2587–2623 | install-cursor | `cursor.desktop` in `~/.local/share/applications`; "Added Cursor to the ChromeOS launcher" | edit, text | Launcher location (Q20); message |
| S25 | 2511–2586 | install-cursor | AppImage run through FUSE (`libfuse2`) | verify | Check an AppImage starts under WSL2 |
| S26 | 2647–2722 | install-windsurf | Devin wrapper, `devin-desktop-x11.desktop`, hidden stock entry, URL handler | edit | Keep wrapper and flag; launcher scheme (Q20); `DONT_PROMPT_WSL_INSTALL` in the wrapper (Q28); messages (2667, 2695) |
| S27 | 2881–2883 and the Qt5 build steps to 3925 | install-lazarus | Qt5 IDE builds, `lazmode` | verify | As-is (see the verdict) |
| S28 | 2927, 3863–3869 | install-lazarus | `lazarus-dark.desktop` in `~/.local/share/applications`; "Added Lazarus (Dark) to the ChromeOS launcher" | edit, text | Launcher location (Q20); message |
| S29 | 3928–3932, 4003–4009 | install-godot | Launchers default to `--rendering-driver opengl3` because virgl has no Vulkan | verify | Keep `opengl3` (plan). Check `glxinfo -B` names D3D12, not llvmpipe |
| S30 | 4020–4037 | install-godot | `.desktop` entries in `~/.local/share/applications`; `Comment=… on Crostini`; "ChromeOS launcher" | edit, text | Launcher location (Q20); texts |
| S31 | 4071–4078 | install-media | Flatpak, HandBrake, KDiff3 | verify | Check Flatpak apps install and start under WSL2 (WSLg lists Flatpak's exports folder) |
| S32 | 4152–4165 | install-antigravity | `.desktop` in `~/.local/share/applications`; "pick it from the ChromeOS launcher" | edit, text | Launcher location (Q20); message |
| S33 | 4082–4151 | install-antigravity | `/opt` install with a setuid `chrome-sandbox` | verify | As-is (works on the Linux filesystem, not under `/mnt`) |
| S34 | 4204–4311 | android-tools (install-mobile, -tauri, -rn, -flutter) | SDK, NDK, Flutter. No `adb connect arc` here | verify | As-is |
| S35 | 4313–4392 | install-android-native | `-cros.deb` scrape (4318–4345), XToolkit pin (4347–4368), `adb connect arc` text (4377–4385) | refused | Forked untouched |
| S36 | 4855–4858, 5182 | install-db-server | Comments: "~6.4 GB of an 8 GB Chromebook" | verify | Comments stay with their code |
| S37 | 4919 | install-db-server | "Give Linux more disk (ChromeOS Settings > …)" | text | WSL wording |
| S38 | 5379 | install-ldap | Comment: slapd on every interface, "which ChromeOS does not forward" | verify | True under NAT too; revisit with Q8 |
| S39 | 5752–5764 | install-ldap (`ldap ui`) | `garcon-url-handler`, else `xdg-open` | replace | The bundle's opener (Q19) |
| S40 | 5564–5574, 5651–5702 | install-ldap-full | `systemctl` for slapd | verify | As-is with systemd |
| S41 | 5828 | shared services | Comment: `vm.max_map_count` cannot be raised in ChromeOS's container | verify | Comment stays; setting works |
| S42 | 6049, 6084, 6732, 6791 | install-redis, install-mongodb | "ChromeOS launcher" in four messages | text | "Start menu" |
| S43 | 6217–6299 | install-typesense | `/proc/self/io` shim | verify | Self-detecting |
| S44 | 7281–7282 | install-gitlab-runner | `systemctl restart gitlab-runner` | verify | As-is with systemd |
| S45 | 7371 | install-puppet | `systemctl disable --now puppet` | verify | As-is with systemd |
| S46 | 7516–7519, 7543–7544, 7567–7569 | install-ollama | Comments: CPU-only in Crostini, the balloon, "sits behind ChromeOS" | verify | Comments stay with their code |
| S47 | 7573–7597 | install-ollama | systemd drop-ins, `systemctl` | verify | As-is with systemd |
| S48 | 7632 | install-ollama | "CPU-only in Crostini." | text | Per machine: CUDA on d1, CPU elsewhere |
| S49 | 7666, 7682, 7908, 7924 | install-gemma, install-models | CPU-only torch index; "8GB Chromebook" comments and one message (7908) | text | Reword 7908. CPU-only torch stays in v1 (Q30) |
| S50 | 7998 | install-models | "Give Linux more disk (ChromeOS Settings > …)" | text | WSL wording |
| S51 | 8246 | install-cloud | Comment names `dev-init-chromebook` | rename | New name |
| S52 | 8515–8520 | install-k8s | Comment: kind verified inside Crostini; the balloon and `free` | verify | Comment stays. Check a kind cluster starts on WSL2 |
| S53 | 8549–9790 | install-lan / install-lan-share | The whole section: `lan`, relay, Tailscale, ChromeOS port-forward text (8583–8593, 8681–8708, 9254–9265, 9309, 9436–9445) | refused | Forked untouched |
| S54 | 9791–9900 | install-com | Wine, widl, winetricks (9830: Crostini has no contrib) | refused | Forked untouched |
| S55 | 9901–13084 | install-retro | kvm group (9973–9982), `/dev/kvm` (11297–11317), ChromeOS key notes (10044, 10116, 11634), launcher argument rejoining (11753–11754, 12201, 12535), launcher entries (12686, 13018), disk message (10624) | refused | Forked untouched |
| S56 | 13136–13143 | install-hermes / install-openclaw | Notes: 8 GB Chromebook, Crostini user's passwordless sudo, container stops when the Chromebook sleeps | text | Reword (Q33 for the last) |
| S57 | 13226–13235 | `stage finalize` | Names the three `-chromebook` scripts (13226–13229); "For GPU acceleration (render group), shut Linux down once: right-click the Terminal icon" (13234–13235) | rename, text | New names; drop the GPU sentence; docker group needs a new terminal or `wsl --terminate <distro>` |
| S58 | 13297, 13345–13346, 13351, 13356 | `stage finalize` | Disk hint (ChromeOS Settings); KVM reminder; agents note; LAN port-forward hint | text | Reword 13297 and 13351; 13345–13346 and 13356 are reached only by refused flags |

### dev-test-chromebook.sh → dev-test-wsl.sh (44 items)

| # | Lines | Section | What is there | Kind | WSL change |
| --- | --- | --- | --- | --- | --- |
| T1 | 2, 6, 47–48 | header | Script names | rename | New names, Version 1 |
| T2 | 83–104 | `>>> dev-bundle host guard >>>` | Same block as setup | replace | Same as S2 |
| T3 | 106–174 | `>>> dev-bundle screen output >>>` | `${_sn%%-chromebook*}` (117) | edit | strip `-wsl` |
| T4 | 189–380 | `FLAG EXPANSION` | Copy of setup's block | new | Same refused list as S5; a refused flag's section is skipped with one line |
| T5 | 437 | paths | Reads `DUCKDB_VERSION` from `dev-setup-chromebook.sh` | rename | New file name |
| T6 | 528, 543–544 | banner, init note | "Testing Chromebook Linux provisioning"; `./dev-init-chromebook.sh` | rename, text | New names |
| T7 | 555 | Base | `check "passwordless sudo (installer ran 'passwd -d')" 'sudo -n true'` | edit | Keep `sudo -n true` (Q7); new label; add a check that the drop-in exists and `visudo -c` passes |
| T8 | after 555 | Base | (new) WSL checks | new | systemd is running (check); bundle not under `/mnt` (check); Windows PATH not appended (warn: user-changeable); the link opener is registered (warn, no live open); X11 and Wayland sockets present (warn) |
| T9 | 590–606 | Base | IPv6 route WARN | verify | Follows S8 |
| T10 | 641–644 | Base | Docker daemon reachable; hint about the docker group | verify | As-is |
| T11 | 883–909 | Base (devmem) | Parses "taken back by ChromeOS (estimate)" (896–900); check label (909) | edit | Follows S19 |
| T12 | 1109–1122 | Base (DDEV) | Router-port check only `if DEV_ON_CHROMEOS` (1112); labels "(ChromeOS passes no 80/443)" | edit | Unconditional (Q17); labels |
| T13 | 1131–1137 | Base (links) | Only when `garcon_host_browser.desktop` exists; WARN unless it is the handler | replace | The new handler (Q19) |
| T14 | 1235–1236 | TanStack | `warn` inotify watches ≥ 30000; hint "if the container refuses" | verify, text | It is a WARN, not a FAIL. Check the WSL kernel's default; reword the hint |
| T15 | 1271 | TanStack | Hint: "localhost:3000, which ChromeOS forwards to the browser" | text | Windows reaches it through localhost forwarding |
| T16 | 1696–1716, 2279, 3100 | .NET, Godot, Test tools | `DOTNET_SYSTEM_NET_DISABLEIPV6=1` | verify | As-is |
| T17 | 1764 | VS Code | `check "code" 'code --version'` | edit | Fails under WSL without `DONT_PROMPT_WSL_INSTALL` (Q28) |
| T18 | 1776 | Cursor | "ChromeOS launcher entry for Cursor": checks `~/.local/share/applications/cursor.desktop` | edit | Follows Q20; label |
| T19 | 1788–1832 | Devin Desktop / Windsurf | X11 entry present; wrapper runs `--ozone-platform=x11`; stock entry hidden; hints say "shut Linux down" | edit | Follows S26 |
| T20 | 1835–2140 | Lazarus | Qt5 builds, `lazmode --check`, the dark launcher | edit | As-is except the launcher's location (Q20) |
| T21 | 2143, 2247–2252 | Godot | Render test labelled "(OpenGL via virgl)"; hint "run the test from the ChromeOS Terminal app" | text | Labels and hint. The test itself (20 frames, `opengl3`) is as-is |
| T22 | 2253 | Godot | `warn "rendering is GPU-accelerated (virgl), not software (llvmpipe)"`: fails only on llvmpipe or softpipe | text | Logic already accepts a D3D12 renderer; label only |
| T23 | 2255–2259 | Godot | `warn "the Linux VM exposes a GPU (/dev/dri/renderD*)"`; hint names `chrome://flags/#crostini-gpu-support` | replace | Expected to WARN under WSL even when accelerated (no render node). Check `/dev/dxg` instead |
| T24 | 2260–2265 | Godot | `warn "sommelier (X11/Wayland bridge) runs with the render group"` | drop | No sommelier under WSL; would always WARN |
| T25 | 2266–2267 | Godot | `warn "this session can open the render node (groups video + render)"` | drop | Would WARN under WSL; setup no longer adds the groups |
| T26 | 2268–2271 | Godot | `warn "the GPU itself is usable (eglinfo, GBM, no window needed)"` | replace | GBM needs a DRM device, which WSLg is not expected to provide, so this would WARN. Verify, then use `glxinfo -B` or `eglinfo` on the X11 or Wayland platform |
| T27 | 2272–2273 | Godot | `warn "X11 apps get a hardware GL renderer (glxinfo)"`; hint names the ChromeOS Terminal app | text | Logic as-is; hint |
| T28 | 2274–2275 | Godot | `slowwarn "Godot on native Wayland gets a hardware renderer"` | verify | Check under WSLg's Weston |
| T29 | 2337–2341 | Android SDK, JDK, NDK (mobile base) | `warn "adb sees this Chromebook's Android runtime"`: `adb connect arc` or `100.115.92.2:5555` | drop | Q10. Reached by install-mobile, -tauri, -rn and -flutter, so it would WARN on every run |
| T30 | 2369–2443 | Native Android / Kotlin | XToolkit check (2371–2377); `-cros.deb` hint (2380) | refused | Forked untouched |
| T31 | 2810–2811, 3596–3598, 3640–3641 | LDAP, GitLab, Puppet | `systemctl is-active` / `is-enabled` | verify | As-is with systemd |
| T32 | 3913, 4124 | Shared services | "…desktop app, in the ChromeOS launcher" (two labels) | text | "Start menu" |
| T33 | 4300–4317 | Ollama server | `systemctl` checks; `OLLAMA_HOST` for containers | verify | As-is with systemd |
| T34 | 4352–4357 | Gemma | Comment about the balloon and the load retry | verify | Comment stays; the retry logic is as-is |
| T35 | 4394, 4439, 4457 | Gemma, Local models | Hints: "closing Chrome tabs…", "give Linux more disk (ChromeOS Settings…)", "close Chrome tabs and Android apps on the ChromeOS side" | text | Windows wording |
| T36 | 4459 | Local models | INFO "(always CPU in Crostini)" | text | Drop the suffix; d1 may show GPU |
| T37 | 5153–5157 | Kubernetes | kind comments (Crostini, crosvm's balloon) | verify | Comments stay |
| T38 | 5175–5435 | Laptop network (three sections) | Tailscale, relay, "ChromeOS forwards to it" | refused | Forked untouched |
| T39 | 5439–5775 | COM development under Wine | Wine checks | refused | Forked untouched |
| T40 | 5776–7440 | DOS / Windows 3.x toolchain | `/dev/kvm` INFO (6036–6039) and the rest | refused | Forked untouched |
| T41 | 7465 | OpenClaw | Hint "(the Crostini user has passwordless sudo)" | text | Reword |
| T42 | 7483–7487 | Disk usage by stack | Comment: every Crostini container is `penguin`; `hostname` fallback | verify | As-is |
| T43 | disk report | Disk usage by stack | "Linux disk" comes from `df` | edit | Add the Windows drive's free space as an INFO row (Q25) |
| T44 | 443 | scratch folder | Comment: Debian 13 mounts `/tmp` as tmpfs | verify | Check it is true under WSL with systemd, and that WSLg's `/tmp/.X11-unix` survives it |

### dev-init-chromebook.sh → dev-init-wsl.sh (23 items)

| # | Lines | Section | What is there | Kind | WSL change |
| --- | --- | --- | --- | --- | --- |
| I1 | 2, 10–11 | header | Script names | rename | New names, Version 1 |
| I2 | 23–44 | `>>> dev-bundle host guard >>>` | Same block as setup | replace | Same as S2 |
| I3 | 72–263 | `FLAG EXPANSION` | Copy of setup's block | new | Same refused list as S5 |
| I4 | 297 | secrets template | "read by dev-init-chromebook" | rename | New name (new files only; an existing `secrets.env` is not rewritten) |
| I5 | 380 | secrets template: This machine | "A short name for THIS Chromebook (e.g. joxer)" | text | "this laptop" |
| I6 | 511–524, 700–708 | secrets template: laptop network, Tailscale | ChromeOS port forwards, Chromebook addresses | refused | Forked untouched (the template writes these sections whatever the flags) |
| I7 | 543 | secrets template: personal agents | "more than an 8 GB Chromebook can hold" | text | Reword |
| I8 | 849, 1777, 2080, 2108 | GitHub, Drupal, GitLab | Key titles `${MACHINE_LABEL:-$(hostname)}` | verify | As-is |
| I9 | 861–864 | Docker | docker group report | verify | As-is |
| I10 | 865–868 | Docker | render-group todo: "shut Linux down (right-click Terminal > Shut down Linux)" | drop | No render group under WSL |
| I11 | 804–805, 887, 1528, 1572, 1582, 1606 | GitHub, Codex, AWS, Google Cloud, Vercel | Interactive logins that open a browser link | verify | As-is; they use the link handler (Q19). Check a localhost callback (codex, gcloud) returns from the Windows browser |
| I12 | 1571 | Google Cloud CLI | Comment: "Chrome is installed in the container, so the browser flow works" | text | The Windows browser handles it |
| I13 | 941–950 | Ollama | `systemctl` enable and the `OLLAMA_HOST` report | verify | As-is with systemd |
| I14 | 1036–1046 | Android (mobile base) | `adb connect arc` (1039) and three ChromeOS todos | drop | Q10. What init says instead is Q34(a) |
| I15 | 1084 | Google Antigravity | "open it from the ChromeOS launcher" | text | Reword |
| I16 | 1185–1199 | Database servers | todos name `./dev-setup-chromebook.sh` | rename | New name |
| I17 | 1235–1238, 2128–2129 | LDAP, Puppet | `systemctl` | verify | As-is with systemd |
| I18 | 1337–1514 | Laptop network (four sections) | Tailscale join, relay, ChromeOS port-forward todos | refused | Forked untouched |
| I19 | 1772 | Godot | "Forward+ and Mobile need Vulkan, which Crostini does not expose" | text | WSLg: OpenGL through D3D12; Vulkan not relied on |
| I20 | 2262–2390 | DOS / Windows 3.x development | KVM todos (2277–2284) | refused | Forked untouched |
| I21 | 2345, 2537 | Personal agents | "8 GB Chromebook"; "the Crostini user has passwordless sudo" | text | Reword |
| I22 | 2455 | Hermes | `loginctl enable-linger` advice for the gateway service | verify | Q33 |
| I23 | 2567 | closing | `./dev-test-chromebook.sh` | rename | New name |

### dev-demo-chromebook.sh → dev-demo-wsl.sh (32 items)

| # | Lines | Section | What is there | Kind | WSL change |
| --- | --- | --- | --- | --- | --- |
| D1 | 2, 10–11 | header | Script names | rename | New names |
| D2 | 25, 31 | header | "opens the browser in ChromeOS"; "these Chromebooks give Linux ~6.4 GB" | text | Reword |
| D3 | 35–56 | `>>> dev-bundle host guard >>>` | Same block as setup | replace | Same as S2 |
| D4 | 85 | version | `VERSION=101` | rename | `1` |
| D5 | 88–280 | `FLAG EXPANSION` | Copy of setup's block | new | Same refused list as S5 |
| D6 | 310, 598 | ENVIRONMENT, launchers | Generated files say "written by dev-demo-chromebook" | rename | New name |
| D7 | 374–382 | `demo_open` | `garcon-url-handler`, else `xdg-open` | replace | The bundle's opener (Q19). Every call site in the demos (about 40) goes through this one function |
| D8 | 383–390 | `demo_ddev_https_port` | Reads DDEV's https port; comment names ChromeOS | verify | As-is |
| D9 | 436–444 | `docker_ok` | "shut Linux down once (right-click the Terminal icon > Shut down Linux)" | text | A new terminal, or `wsl --terminate <distro>` |
| D10 | 624–647 | base/voting-app | Moved to 8090/8091 because DDEV's router holds 8080 | verify | As-is (Q17 keeps 8080) |
| D11 | 751 | asm-arm/aarch64-hello | Program text "…on an x86-64 Chromebook!" | text | Reword (Q34) |
| D12 | 789–806, 863, 876, 9789 | dotnet, pwsh, testing | `DOTNET_SYSTEM_NET_DISABLEIPV6=1` | verify | As-is |
| D13 | 980 | lazarus/examples | Opens Devin through its X11 wrapper | verify | Follows S26 |
| D14 | 1003–1004 | lazarus/examples | TDaemon's `systemctl` steps | verify | As-is with systemd |
| D15 | 1204–1430 | drupal/drupal-rag | `host.docker.internal:11434`; generated site content: "Run order of the Chromebook bundle", "Memory on an 8 GB Chromebook", "CPU-only in Crostini" (1250–1274) | text | Container route as-is; rewrite the content (Q34) |
| D16 | 1627–1632 | drupal/drupal-ldap | `host.docker.internal:389` | verify | As-is |
| D17 | 1712 | godot/demo-projects | Note: "the renderer virgl supports" | text | Reword |
| D18 | 1748 | rn/expo-router | Note: "Crostini has no Android emulator" | text | No emulator in v1 |
| D19 | 1771 | tauri/tauri-app | WebKitGTK's DMA-BUF renderer disabled for virgl | verify | Check the window draws under WSLg |
| D20 | 1780–1797 | android-native/jetnews | `adb connect arc` (1787), ChromeOS notes | refused | Forked untouched |
| D21 | 1816, 2315, 2480, 2512, 2545 | gemma, models, agentic | "sudo systemctl start ollama" | verify | As-is with systemd |
| D22 | 2238–2276 | models/local-rag | Corpus text about the Chromebook bundle | text | Rewrite (Q34) |
| D23 | 3188, 3218, 3289 | k8s, iac, ansible | Demo strings "…on a Chromebook" | text | Reword (Q34) |
| D24 | 3633 | media/sintel | `demo_open "file://$DEMO_DIR/sintel.gif"` | verify | Local-path case of the opener (Q19) |
| D25 | 3649–3893 | DEMOS: laptop network | net/mcp-hello | refused | Forked untouched |
| D26 | 3919 | INDEX | README header: "Hands-on demos for the Chromebook dev environment" | text | Reword |
| D27 | 3988–5258 | DEMOS: COM under Wine, and retro | com/hello-com, retro/* | refused | Forked untouched |
| D28 | 5386–5389, 5422, 5437, 5566–5569, 5637 | DEMOS: personal agents | Skill files: "this Chromebook's dev-setup bundle"; "the container sleeps with the Chromebook" | text | Rewrite (Q34) |
| D29 | 7198 | services/mongodb | "Compass (ChromeOS launcher)" | text | "Start menu" |
| D30 | 8752 | drupal/drupal-graphql | Suggests `ddev hostname … 127.0.0.1` | verify | DDEV's docs say custom host names belong in the Windows hosts file under WSL2. Check, then adjust the note |
| D31 | 9857–9867 | testing/e2e-bakeoff | Grid browser reaches the app at `host.docker.internal`; noVNC opened with `demo_open` | verify | As-is |
| D32 | 10563, 10783, 10873 | drupal-astro, drupal-nuxt | "Drupal stays on the Chromebook" | text | Reword |

### Counts per script

| Script | Items | replace | drop | edit | text | rename | new | verify | refused |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| setup | 58 | 5 | 1 | 10 | 9 | 4 | 4 | 21 | 4 |
| test | 44 | 4 | 3 | 9 | 8 | 3 | 2 | 11 | 4 |
| init | 23 | 1 | 2 | 0 | 6 | 4 | 1 | 6 | 3 |
| demo | 32 | 2 | 0 | 0 | 12 | 3 | 1 | 11 | 3 |
| **Total** | **157** | **12** | **6** | **19** | **35** | **14** | **8** | **49** | **14** |

An item with two kinds (for example "edit, text") is counted under the first.

*Added 2026-11-11, while writing the v1 plan:* four places this inventory missed, numbered S59, T45,
T46 and I24, are listed in [v1-plan.md](v1-plan.md), section 2 ("Four additions to Part B"). They are
install-models' own `df` reading (setup 7991) and three checks that look for a launcher in
`~/.local/share/applications` (test 2242 and 2321, init 1735). With them the worklist is 161 items.
The tables and counts above are left as reviewed.

The host guard, the flag-expansion block and the screen-output block are each one piece of text
repeated across scripts: 4 guards, 4 expansions and 2 recorders above are 3 pieces of work.

---

## Part C: findings for the owner

### C1. Candidates for the "not yet supported on WSL" list

**No flag has to be added.** v1's list (install-lan, install-lan-share, install-android-native,
install-retro, install-com) already covers everything that depends on something WSL lacks. Three
observations about the list as it stands:

- **Two groups contain a refused member.** `install-ecosystems` (and so `install-all`) includes
  install-android-native; `install-retro` pulls in install-com; `install-lan-share` pulls in
  install-lan. The PR #1 follow-up decision (any group skips a refused member with a notice) covers
  all three.
- **Two commands inside supported flags belong to a refused one.** `delphi N build` and
  `delphi N vscode` were added under v96's Lazarus work but live in install-retro's helper, so they
  come off the list with it.
- **usbipd-win has no user in v1.** With install-android-native refused and install-mobile's
  `adb connect arc` steps removed, nothing in v1 attaches a USB device (Q34).

**Watch list:** flags that stay in v1 but have a first-run check that could move them onto the list.
None is a recommendation to refuse now.

| Flag | Why it is on the watch list | What decides it |
| --- | --- | --- |
| install-media | Flatpak needs user namespaces and a session bus; untested under WSL2 | HandBrake and KDiff3 install and open on d3 |
| install-cypress (opt-in) | Electron under Xvfb in WSL is untested | The test's headless run passes |
| install-gitlab-runner, install-ldap-full, install-puppet (opt-in) | Each manages a systemd service | They pass with systemd on |
| install-hermes, install-openclaw (opt-in) | Their optional gateway services assume a machine that stays up; WSL stops an idle VM | Q33 |
| install-windsurf | The launcher scheme does not fit WSLg | Q20 |

### C2. Flags that likely need AVX (for d4's per-machine notes)

Nothing in the four scripts, their comments or the Chromebook docs mentions AVX (a search for `avx`,
`sse4`, `x86-64-v` and "illegal instruction" found nothing). The list below comes from vendor sources
where they exist, and is marked "verify on d4" where they do not.

| Flag | Component | Evidence | Status |
| --- | --- | --- | --- |
| install-mongodb (in install-all) | MongoDB 8 container | MongoDB 5.0+ requires AVX on x86-64 (MongoDB's platform notes and forum answers) | **Documented: cannot run on d4** (already recorded) |
| install-mongodb-atlas-local (opt-in) | Atlas Local image | Contains the same server | Treat as the row above; verify on d4 |
| install-vector (in install-all) | sqlite-vec loadable extension | Its Makefile adds `-mavx -mavx2` on Linux when the build machine reports AVX, so the published build very likely uses it | Verify on d4 |
| install-ollama, install-gemma, install-models | Ollama's bundled runners | The installer has no CPU check; older prebuilt runners assumed AVX; current behaviour on a CPU without it is unconfirmed | Verify on d4 |
| install-gemma | PyTorch CPU wheel | No vendor statement found | Verify on d4 (`import torch`) |
| install-search, install-vector, install-db-server (and opt-ins) | Typesense, Meilisearch, Qdrant, Milvus, Elasticsearch, OpenSearch, SQL Server 2025, Oracle Free | No vendor statement found in this session | Verify on d4, one `devsvc up` or `mssql up` each |

On d4 the practical first step is a run with a small flag set, then `devsvc up <name>` for each engine
in turn, noting any "illegal instruction" or exit code 132.

### C3. New open questions

Numbered after the plan's Q18. Each has a recommendation; none is decided.

- **Q19. How do links from WSL open in the Windows browser?** The plan says `wslu`'s `wslview`.
  `wslu` is discontinued and archived upstream, Ubuntu 26.04 dropped it, its presence in Debian 13 is
  unconfirmed, and `wslview` needs Windows programs on the PATH that Q9 removes. *Recommendation:* the
  bundle writes its own opener in `~/.local/bin` (a few lines: convert a local path with `wslpath`, then
  call a Windows program by absolute path found with `wslpath`, not through PATH), plus a `.desktop`
  handler registered with `xdg-mime` exactly where the Chromebook script registers
  `garcon_host_browser.desktop`. `demo_open` and `ldap ui` call it; init's logins reach it through
  `xdg-open`. No `wslu`. Confirm on the first run that `xdg-open` on Debian 13 honours the registered
  handler under WSL.
- **Q20. Where do the bundle's launchers go?** WSLg lists only `/usr/share/applications`,
  `/usr/local/share/applications`, snap's folder and Flatpak's exports; it skips entries with
  `NoDisplay=true` or `Terminal=true`. The bundle writes Cursor, Godot, Devin (X11), Lazarus (Dark),
  Antigravity (and, later, the retro guests) into `~/.local/share/applications`.
  *Recommendation:* in the WSL bundle those entries go to `/usr/local/share/applications` (same file
  names, written with `sudo install`), and the test checks that folder. For Devin, keep the "(X11)"
  entry there and accept that the stock entry also shows, after checking on the first run whether the
  stock one works under WSLg. Alternative: no Start menu entries, editors started from the terminal.
- **Q21. Who writes the sudoers drop-in (Q7)?** Setup must not prompt (rule 7), but writing
  `/etc/sudoers.d/…` needs root. *Recommendation:* `dev-host-wsl.ps1` writes it as root
  (`wsl -u root`), validated with `visudo -c`; setup's preflight runs `sudo -n true` and stops with the
  host-script instruction if it fails. Alternative: setup writes it and asks for the password once on
  its first run.
- **Q22. Does the WSL host guard keep a bypass variable, and what replaces `DEV_ON_CHROMEOS`?**
  The Chromebook guard offers `DEV_BUNDLE_ANY_HOST=1`, and AGENTS.md says it is never used to force a
  run. *Recommendation:* keep the same variable name and wording (the guard stays a straight edit and
  the rule in AGENTS.md keeps meaning something), and set `DEV_ON_WSL` where the Chromebook guard sets
  `DEV_ON_CHROMEOS`, so the two remaining conditions that need one keep their shape. Also check for
  WSL 2 specifically, since WSL 1 has no systemd, Docker or WSLg.
- **Q23. Should the guard also require Debian 13?** The Chromebook guard checks `ID=debian` only.
  *Recommendation:* same check as the Chromebook (diffable); the preflight warns when `VERSION_ID` is
  not 13.
- **Q24. How does the Windows browser come to trust mkcert's CA?** The plan says "Windows-side trust
  step, printed as instructions". Two routes: (a) DDEV's documented one: `mkcert -install` on Windows,
  then `CAROOT` shared into WSL through `WSLENV`, so one CA serves both sides; (b) keep the CA in WSL
  and import its public certificate into the Windows store. *Recommendation:* (a), done by the host
  script, because it is the route DDEV documents and tests, and one CA per laptop also serves the
  native dev-setup-windows bundle. It makes the host script's "mkcert trust on Windows" a real step
  that must run before setup's `mkcert -install`.
- **Q25. Disk guards and the VHDX.** `df` inside WSL reports the virtual disk's size, not how full
  the Windows drive is. The guards for install-models, install-db-server and (later) install-retro,
  `devclean`'s free-space lines and the test's disk report all read it. *Recommendation:* the two
  helper functions (`disk_margin_gb`, `disk_free_gb`) also read the Windows drive that holds the VHDX
  and use the smaller figure; the disk report gains one INFO row for it. Confirm on d3 that `df` on
  the Windows drive's mount gives a usable number.
- **Q26. Sparse VHD (Q18, second look).** It is an experimental setting; `sparseVhd=true` affects
  only disks created afterwards; an existing distro needs `wsl --manage <distro> --set-sparse true`;
  in 2025 that was blocked behind `--allow-unsafe` over a corruption risk, and later reports say it
  was re-enabled. *Recommendation:* the host script sets it only where the installed WSL accepts it
  without `--allow-unsafe`, and never passes that flag; otherwise it prints how to compact the disk
  by hand. Decide after the first d3 run, as Q18 already says.
- **Q27. The IPv4 preference check under NAT.** It may apply its fix on every laptop, for a reason
  different from the one it was written for. *Recommendation:* keep it unchanged in v1 (the fix is
  harmless: IPv6 stays on), record what it prints on d3, and only then decide whether to add "skip
  when this machine has no global IPv6 address". That change would port to the Chromebook bundle.
- **Q28. VS Code's WSL question.** `/usr/bin/code` asks "please install VS Code in Windows… Do you
  want to continue anyway? [y/N]" under WSL and exits 1 on anything but yes, unless
  `DONT_PROMPT_WSL_INSTALL` is set. Q6 chose WSLg editors for v1, so this is in the way.
  *Recommendation:* set the variable in a marked `~/.bashrc` block, in the test's environment, and in
  the Devin wrapper. Check on the first run whether Cursor's and Devin's launcher scripts carry the
  same check.
- **Q29. Preflight: where it sits and what else it checks.** *Recommendation:* directly after the
  host guard and before the screen-output block, so a refused run writes nothing, not even a log.
  Add three checks to the plan's five: not running as root, `sudo -n true` works (Q21), and WSL 2.
- **Q30. Ollama settings and CPU-only torch were sized for 8 GB Chromebooks.** Two loaded models, an
  8K context, a q8_0 cache; `torch` from the CPU index. *Recommendation:* keep both in v1 (parity, and
  Q5 already puts benchmarking later); revisit per machine with Q5's follow-up.
- **Q31. `devmem`'s residual line.** *Recommendation:* rename it "not accounted for (estimate)",
  drop the "ChromeOS has taken back" verdict, keep every other verdict, and reword the Linux Chrome
  one ("links open in the Windows browser"). The test's label check follows.
- **Q32. Code inside refused flags.** About 4,600 lines of setup (install-lan, install-com,
  install-retro, install-android-native) and their test, init and demo sections still say ChromeOS.
  *Recommendation:* fork them untouched and edit each when its flag comes off the list. Part B marks
  them "refused" (14 items) and does not itemise their insides.
- **Q33. Services and the WSL VM's lifetime.** WSL is reported to shut an idle VM down some time
  after the last session ends (not confirmed from a source in this session), which would stop Ollama,
  autostarted `devsvc` containers, slapd and any agent gateway. The Chromebook texts say services
  "start with Linux". *Recommendation:* nothing in v1's code; observe it on d3, describe it in the WSL
  gotchas doc and reword the two agent notes. Whether the host script should keep the distro alive is
  a later question.
- **Q34. Three smaller scope points.** (a) After `adb connect arc` goes, what do init and test say
  for install-mobile? *Recommendation:* init prints one skip line ("no Android device in v1"); the
  test drops the WARN. (b) usbipd-win in the host script. *Recommendation:* leave it out of v1 and add
  it with Android. (c) Demo text that describes the machine as a Chromebook, including the corpus the
  RAG demos answer from and the agents' skill files. *Recommendation:* rewrite it in v1; it is
  generated text, not logic, and a RAG demo that describes the wrong machine is a visible fault.

### C4. What the review shows to be wrong or stale in wsl-plan.md

1. **"Install `wslu`; `demo_open` and `BROWSER` use `wslview`"** (compatibility review, Browser
   opening; "Browser standard"; Q9's "verify that `wslview` works"; AGENTS.md's hazards). Stale: see
   Q19. Also, the Chromebook mechanism is an `xdg-mime` handler, not `BROWSER`.
2. **"`.desktop` entries appear in the Windows Start menu via WSLg"** (Editors and launchers row).
   True only for the system folders; the bundle's own entries are in a folder WSLg does not read
   (Q20).
3. **"`adb connect arc` (setup, test, init)"** (Android row, Q10). Setup has it only in
   install-android-native's closing text. install-mobile's steps are init 1036–1046 and test
   2337–2341; demo's is in android-native/jetnews. Q10 itself is confirmed.
4. **"DDEV ports … keep 8080/8443"** reads as no work. The code is ChromeOS-conditional in setup and
   test (A54).
5. **"inotify watches may fall under the test's 30000"** and AGENTS.md's "inotify via `sysctl`".
   The test's check is a WARN, not a FAIL, and its hint already names the `sysctl`. No setup or
   host-script step is shown to be needed; verify the default on d3 first.
6. **Q18's "enables sparse VHD so freed space returns to Windows".** Not that simple (Q26). Also
   missing from the Resources row: swap defaults to 25% of Windows memory, and cached memory is
   handed back by default.
7. **"Preflight: CRLF, `/mnt/*`, systemd, Windows PATH, Docker Desktop".** Three more candidates:
   root user, `sudo -n true`, WSL 2 (Q29).
8. **Host-script scope: "usbipd-win".** Nothing in v1 uses it (Q34b). And "mkcert trust on Windows"
   may need to run before setup, not after (Q24).
9. **The "Flags added v77–v93" list** names install-herdr (v95, a flag in `install-all`) only as
   "herdr", in the v94–v101 paragraph. *Corrected 2026-11-11 (PR #2 review): this item first said six
   flags were missing. That was wrong for five of them. install-ollama-containers, install-oracle-full,
   install-gitlab-runner, install-cloudflared and install-vue are in the list, inside longer items or
   italic asides, where they are easy to miss. Part A has all six.*

Confirmed as written: the systemd row (Microsoft documents `systemd` in `wsl.conf` as off unless
set; the state of Debian's own image could not be checked, so the host script setting it is right
either way); the GPU row's direction (no virgl, render node or sommelier; whether Debian 13's Mesa
build includes the d3d12 driver is unverified); the `passwd -d` row; the Windows PATH,
bundle-location and line-ending rows;
the 22H2 minimum for mirrored networking; Ollama's CUDA-only GPU path under WSL2.

### C5. First-run checks on d3

The "verify on first run" items from Parts A and B in one place, in the order a first run meets them.
Each is something this review could not confirm from a source.

1. Debian's WSL image: is systemd already on, or only after the host script sets it?
2. `dockerd` starts with Debian 13's iptables under the WSL kernel (S11).
3. `/tmp` is a tmpfs under systemd, and WSLg's `/tmp/.X11-unix` is still there afterwards (T44).
4. What the IPv4 preference check prints under NAT (S8, Q27).
5. `glxinfo -B` names a D3D12 renderer, not llvmpipe, which shows Debian 13's Mesa includes the d3d12
   driver; `/dev/dxg` exists and is usable by the user (S12, S29, T23, T26).
6. Linux Chrome, an AppImage (Cursor), Redis Insight and Compass start under WSLg (S16, S25, A27).
7. `xdg-open` honours the registered handler, a sign-in callback on localhost returns from the Windows
   browser, and a `file://` path opens (Q19, I11, D24).
8. A DDEV site opens at `https://<site>.ddev.site:8443` in the Windows browser, without a certificate
   warning once Q24's step has run (A54, S13).
9. Whether Cursor's and Devin's launcher scripts ask VS Code's WSL question, and whether Devin's stock
   Start menu entry works (Q20, Q28).
10. The Qt5 Lazarus IDE: dialogs take focus, the floating layout behaves, the dark palette applies.
11. The inotify default (T14) and whether the kernel provides `/proc/self/io` (S43).
12. `df` on the Windows drive's mount gives a usable free-space figure (Q25).
13. Flatpak apps (install-media), a kind cluster, Playwright headed runs, Cypress under Xvfb.
14. What happens to Ollama and autostarted containers after the last terminal closes (Q33).
15. On d1: Ollama uses CUDA. On d4: the AVX list in C2.

---

## Sources

- Microsoft, *Advanced settings configuration in WSL* (read from the docs' GitHub source):
  <https://github.com/MicrosoftDocs/WSL/blob/main/WSL/wsl-config.md>. `systemd` default false;
  `appendWindowsPath` default true; `memory` 50%; `swap` 25%; `localhostForwarding` default true;
  `nestedVirtualization` default true (Windows 11); `networkingMode` needs Windows 11 22H2;
  `autoMemoryReclaim` default `dropCache`; `sparseVhd` default false, new disks only.
- Microsoft, WSLg README: <https://github.com/microsoft/wslg/blob/main/README.md>. Weston, XWayland,
  PulseAudio, Mesa's d3d12 driver "upstream … part of the Mesa 21.0 release", and that the distro must
  ship it.
- Microsoft, weston-mirror, `rdprail-shell/app-list.c`:
  <https://github.com/microsoft/weston-mirror/blob/working/rdprail-shell/app-list.c>. The four folders
  WSLg scans, and the NoDisplay / Terminal filter.
- Microsoft, VS Code's Linux launcher script:
  <https://github.com/microsoft/vscode/blob/main/resources/linux/bin/code.sh>. The WSL question and
  `DONT_PROMPT_WSL_INSTALL`.
- Microsoft devblog, *Windows Subsystem for Linux September 2023 update* (sparse VHD,
  `autoMemoryReclaim`, `wsl --manage --set-sparse`):
  <https://devblogs.microsoft.com/commandline/windows-subsystem-for-linux-september-2023-update/>
- microsoft/WSL issue 13075 (sparse VHD blocked behind `--allow-unsafe`):
  <https://github.com/microsoft/WSL/issues/13075>
- DDEV, installation docs (GitHub source):
  <https://github.com/ddev/ddev/blob/main/docs/content/users/install/ddev-installation.md> and
  <https://github.com/ddev/ddev/blob/main/docs/content/users/install/docker-installation.md>. Docker CE
  inside WSL2 as the recommended provider; mkcert on Windows with `CAROOT` through `WSLENV`; custom
  host names in the Windows hosts file; projects in the Linux filesystem.
- DDEV issue 8326 and PR 8351 (wslu discontinued and archived; removed from the Windows installer,
  April 2026): <https://github.com/ddev/ddev/issues/8326>, <https://github.com/ddev/ddev/pull/8351>
- wslu upstream: <https://github.com/wslutilities/wslu>. Ubuntu bug 2131669, "Drop the wslu package
  from the archive": <https://lists.snapcraft.io/archives/ubuntu-archive/2025-December/113453.html>.
  Launchpad bug 1877016 (wslu needs Windows directories on PATH):
  <https://bugs.launchpad.net/bugs/1877016>
- Ollama, `scripts/install.sh`: <https://github.com/ollama/ollama/blob/main/scripts/install.sh> (WSL2
  branch, systemd handling, no CPU-feature check); GPU docs:
  <https://github.com/ollama/ollama/blob/main/docs/gpu.mdx> (driver versions).
- sqlite-vec, `Makefile` (AVX flags on Linux): <https://github.com/asg017/sqlite-vec/blob/main/Makefile>
- MongoDB community forum, MongoDB 5.0 CPU requirements:
  <https://mongodb.com/community/forums/t/mongodb-5-0-cpu-intel-g4650-compatibility/116610>
- Mesa, D3D12 driver docs: <https://docs.mesa3d.org/drivers/d3d12.html>

Not reachable from this session, so not checked: Debian's package pages (whether trixie carries
`wslu`, and whether its Mesa build includes the d3d12 driver), `learn.microsoft.com` directly, and
`docs.ddev.com` directly.
