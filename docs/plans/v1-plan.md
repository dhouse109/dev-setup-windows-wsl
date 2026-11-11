# dev-setup-windows-wsl v1 plan

2026-11-11 · step 4 of the suggested sequence in [wsl-plan.md](wsl-plan.md) · **draft, pending owner
review** · 23 questions for the owner in section 6

This is the build spec for step 5: the preliminary build in the cloud, on `release/v1`. It says what
gets built, in which order, how the first run on d3 goes, and when v1 counts as done. It is the approved
decisions turned into a worklist; it decides nothing new. Where the build needs something that is not
settled, it is a question in section 6 with a recommendation, and the text marks the spot with
**(P*n*)**.

Inputs, read in this order:

1. [wsl-plan.md](wsl-plan.md), "Decisions so far": every decision this plan rests on (Q1–Q34 except
   Q8, which stays open, plus the PR #1 follow-up rows).
2. [v1-wsl-review.md](v1-wsl-review.md): Part A (what v77–v101 added), Part B (the 157-item
   inventory this plan maps to stages) and C5 (the first-run checks).
3. `reference/dev-setup-chromebook/` at v101 (`68113ff`): the fork source. Read-only.

## 1. Scope

**v1 is a straight fork of Chromebook v101, plus the WSL edits, the refused list and the host script.**

- **The four bash scripts**, forked whole under their `-wsl` names (Q2, Q13), with the edits in Part B
  of the review and nothing else. Same flags, same section order, same headings, so `diff -u` against
  the reference shows only platform differences.
- **The "not yet supported on WSL" list** (Q13): install-lan, install-lan-share,
  install-android-native, install-retro, install-com. Naming one stops before anything installs; any
  group, `install-all` included, skips a refused member with a notice. Their code is forked untouched
  (Q32).
- **`dev-host-wsl.ps1`** (Q2, Q3): new, with no Chromebook counterpart.
- **Around them:** `CHANGELOG.md` with five sections, the README's flag tables, CI's version and
  PowerShell checks, and three docs.

**Not in v1**, each already decided: the five refused flags; Tailscale and mirrored networking (Q8);
Windows-side editors (Q6); native Windows Ollama (Q5); usbipd-win (Q34); per-machine tiers (Q14); a
shared `dev-common.sh`.

**What the build produces:** v1 "built, not yet confirmed run in WSL". Nothing is run in the cloud
(AGENTS.md, "Where you are running"). The build is checked by `bash -n`, `shellcheck -S error`, the
PowerShell checks and by reading diffs. Section 3 is where it first runs.

## 2. Build stages

Nine stages, one commit each, on `release/v1`, in this order. Rules for every stage:

- **Lint-clean on its own:** `bash -n` and `shellcheck -S error` on each `dev-*.sh` before the commit;
  from stage 7 on, the PowerShell parse check and PSScriptAnalyzer at Error severity. No tracked
  symlinks, LF everywhere except `*.ps1`.
- **Targeted edits only.** Never regenerate a script or reformat a section (AGENTS.md, "Diffable
  fork").
- **Comments (rule 3).** Inherited tagged comments stay. A Crostini comment goes only when the code it
  explains changes or goes, and its replacement is tagged `# v1:` with the WSL reason and, where there
  is one, the decision (`# v1: … (Q17)`).
- **The scripts are not consistent with each other until stage 6 is in.** Between stages 3 and 5, for
  example, setup writes launchers where the test does not yet look. That is expected; nothing runs
  before stage 9.
- **After each stage**, `diff -u reference/dev-setup-chromebook/dev-X-chromebook.sh dev-X-wsl.sh`
  should show only that stage's items and the earlier ones. A hunk nobody can name is a mistake.

### Where the Part B items go

Every Part B item is closed by exactly one stage. Three rules keep that unambiguous:

- **Stage 1 does every rename** (script names, the `-chromebook` suffix, version strings) across all
  four scripts in one pass. An item that is *only* a rename closes there. An item that is a rename
  plus something else closes in the stage that does the something else.
- **"verify" items** (no code change expected) and **"refused" items** (forked untouched, Q32) close
  in stage 1, because forking them unchanged is all the build does with them. The verify items come
  back in section 3 as first-run checks.
- **Test items close in stage 5**, including the test's own text items. Text items in setup, init and
  demo close in stage 6.

| Stage | What | Part B items closed | Count |
| --- | --- | --- | --- |
| 1 | Fork and rename | **Renames:** S1 S4 S51 · T1 T3 T5 · I1 I4 I16 I23 · D1 D4 D6. **Forked unchanged, first-run check:** S8 S11 S13 S16 S20 S25 S27 S29 S31 S33 S34 S36 S38 S40 S41 S43 S44 S45 S46 S47 S52 · T9 T10 T16 T28 T31 T33 T34 T37 T42 T44 · I8 I9 I11 I13 I17 I22 · D8 D10 D12 D13 D14 D16 D19 D21 D24 D30 D31. **Refused, forked untouched:** S35 S53 S54 S55 · T30 T38 T39 T40 · I6 I18 I20 · D20 D25 D27 | 75 |
| 2 | Host guard, preflight, refused list | S2 S3 S5 S6 · T2 T4 · I2 I3 · D3 D5 | 10 |
| 3 | Setup base edits | S9 S10 S12 S14 S15 S17 S18 S19 S21 S22 S23 S39 S57 | 13 |
| 4 | Launchers and GUI apps | S24 S26 S28 S30 S32 S42 | 6 |
| 5 | Test checks | T6 T7 T8 T11 T12 T13 T14 T15 T17 T18 T19 T20 T21 T22 T23 T24 T25 T26 T27 T29 T32 T35 T36 T41 T43 | 25 |
| 6 | Init, demo and remaining text | S7 S37 S48 S49 S50 S56 S58 · I5 I7 I10 I12 I14 I15 I19 I21 · D2 D7 D9 D11 D15 D17 D18 D22 D23 D26 D28 D29 D32 | 28 |
| 7 | `dev-host-wsl.ps1` and its CI job | none (new file) | 0 |
| 8 | CHANGELOG, README, version check | none | 0 |
| 9 | Docs | none | 0 |
| | | **Total** | **157** |

**Four additions to Part B, found while writing this plan.** Each is a place the review's inventory
missed. They are added here rather than renumbering the reviewed inventory:

| # | Lines (v101) | What is there | Stage | Change |
| --- | --- | --- | --- | --- |
| S59 | setup 7991 | install-models reads `df` on the model store itself, beside the `disk_margin_gb` call at 7955 | 3 | Same rule as S22 (Q25): the smaller of the Linux and Windows figures |
| T45 | test 2242 | "app-drawer entries for both editors" looks for Godot's entries in `~/.local/share/applications` | 5 | Follows S30 (Q20); label |
| T46 | test 2321 | The Antigravity check looks for its entry in `~/.local/share/applications` | 5 | Follows S32 (Q20) |
| I24 | init 1735 | The Lazarus section looks for `lazarus-dark.desktop` in `~/.local/share/applications` | 6 | Follows S28 (Q20) |

With them the worklist is 161 items. The stage that changes a launcher's folder should end with
`grep -n 'share/applications\|share/icons'` over the four scripts, outside the refused sections, to
confirm nothing still points at the old place.

**Two changes to the suggested order, and why.** The PowerShell CI job moves from stage 8 to stage 7,
into the same commit as the host script, so that stage is checked by CI on its own instead of waiting
one commit for its linter. And stage 6 takes setup's leftover text items as well as init's and demo's,
so stages 3 and 4 stay small enough to review hunk by hunk. Otherwise the order is as suggested
**(P23)**.

### Stage 1: fork and rename

**What.** Copy the four reference scripts to the repo root as `dev-setup-wsl.sh`, `dev-test-wsl.sh`,
`dev-init-wsl.sh` and `dev-demo-wsl.sh`, recorded in Git as mode 100755 (review A67). Then one
mechanical pass:

- every occurrence of the four `dev-*-chromebook` script names becomes the `-wsl` name (headers, usage
  lines, the NEXT block, rerun lines, todos, generated files' headers, the test reading
  `DUCKDB_VERSION` out of the setup script);
- the recorder's `${_sn%%-chromebook*}` becomes `${_sn%%-wsl*}` (S4, T3), so logs keep the names
  `dev-setup-<date-time>.output` and `dev-test-<date-time>.output`;
- "Version 101" becomes "Version 1" wherever the version is printed or matched, and demo's
  `VERSION=101` becomes `VERSION=1`;
- each header gains one line: based on dev-setup-chromebook v101.

Version tags inside comments (`# v96: …`) are history and do not change.

**Done when** `diff -u` of each script against its reference shows renames and version strings only,
and the four files are 100755. While doing it, write down every place the version string appears;
stage 8 needs that list for AGENTS.md rule 1.

### Stage 2: host guard, preflight and the refused list

**Host guard (S2, T2, I2, D3; Q22, Q23).** The same block in all four scripts, edited in place:

- WSL is detected by `$WSL_DISTRO_NAME` or `/proc/sys/fs/binfmt_misc/WSLInterop`, and sets
  `DEV_ON_WSL=1` where the Chromebook guard sets `DEV_ON_CHROMEOS`. **(P1)** covers two details the
  decisions leave open: a second interop file name, and how WSL 2 is told from WSL 1.
- WSL 1 is refused with its own message.
- The Debian check and the `DEV_BUNDLE_ANY_HOST` offer keep their wording, with "ChromeOS's Linux"
  replaced by "Debian on WSL2".

**Preflight (S3; Q29).** Setup only, a new marked block directly after the guard and before the
screen-output block, so a refused run writes nothing. Each check that fails stops the run with one
message that names the fix. In this order:

| # | Check | On failure |
| --- | --- | --- |
| 1 | Not running as root | Stop: run as the distro's user |
| 2 | The bundle folder is not under `/mnt/*` | Stop: clone into the Linux home |
| 3 | No CR line endings in the sibling `dev-*.sh` files | Stop: name the files and the `.gitattributes` fix |
| 4 | systemd is running | Stop: run the host script, then `wsl --shutdown` |
| 5 | No Windows directory on `PATH` | **(P2)**: stop or warn |
| 6 | Docker Desktop's WSL integration is not on for this distro | Stop (Q4). How it is detected is **(P3)** |
| 7 | `sudo -n true` works | Stop: the host script writes the drop-in (Q21) |
| 8 | Debian's `VERSION_ID` is 13 | Warn only (Q23) |

One limit to state in the code comment: a script cannot check itself for CRLF, because bash fails on
its first line before any check runs. Check 3 protects the *other* scripts, which the owner runs next;
`.gitattributes` protects all of them.

**Refused list (S5, T4, I3, D5; Q13).** One list, defined once at the top of the `FLAG EXPANSION`
block, identical in all four scripts (the block stays "copied verbatim from the installer"):

- **Before expansion:** if the command line names a refused flag, print one line per flag with its
  reason and exit 1. Nothing has been installed or written.
- **After the dependency guards:** remove any refused flag from `FLAGS` and print one NOTICE per flag
  ("skipped: not yet supported on WSL"). This is what handles `install-ecosystems` and `install-all`
  bringing in install-android-native.
- The reasons, one line each, are **(P4)**.

**S6.** `stage_expect` only registers a stage when one of its flags is in `FLAGS` (setup 362–375), so a
stripped flag's stages are simply not expected and cannot show as "not reached". Confirmed by reading
the code; no change beyond stage 1's rename of the rerun line.

**Done when** all four scripts carry byte-identical guard and flag-expansion blocks (`diff` them
against each other), and setup alone carries the preflight.

### Stage 3: setup base edits

All in `dev-setup-wsl.sh`, in the order the script reaches them.

| Item | Section | Edit |
| --- | --- | --- |
| S9 | `stage system` | Remove `sudo passwd -d "$USER"` and its comment. Replace with a `# v1:` comment: sudo is passwordless through the drop-in the host script wrote (Q7, Q21), and the preflight has already checked it |
| S10 | `stage ssh` | The key comment `$USER@chromebook` gets a machine name **(P5)** |
| S12 | `stage docker` | Remove the `video` / `render` loop and its comment. `# v1:` WSLg's GPU is `/dev/dxg`, with no render node and no group to join |
| S14 | `stage homebrew` | DDEV's 8080/8443 step runs unconditionally: drop the `DEV_ON_CHROMEOS` branch, reword the two messages. `# v1:` the reason on WSL is parity with the Chromebooks (Q17), not a forwarding limit |
| S15 | `stage homebrew` | Replace the ChromeOS certificate-import instructions with a short report: whether mkcert's CA folder is the one shared from Windows (Q24), and if not, a NOTICE naming the host-script step. Whether setup also writes `CAROOT` somewhere is **(P6)** |
| S17, S23 | `stage chrome` | Replace the `garcon_host_browser.desktop` block with three things (Q19, Q28). (1) The opener, written to a `.new` file and moved into place as `devmem` is. (2) A handler entry for it, `NoDisplay=true`, in `~/.local/share/applications`, registered with `xdg-mime default` for the same three types as on the Chromebook. It is not a launcher, so Q20 does not move it. (3) A marked `~/.bashrc` block, rewritten in place, that exports `BROWSER` and `DONT_PROMPT_WSL_INSTALL=1`; both are exported for the rest of the run too. Names are **(P7)** |
| S39 | install-ldap | `ldap ui` calls the opener, else `xdg-open` |
| S18, S19 | `stage devmem` | Q31: the residual line becomes "not accounted for (estimate)"; the "ChromeOS has taken back" verdict goes; the Linux Chrome verdict says links open in the Windows browser; header comments and the closing echo follow |
| S21 | `stage devclean` | One note in `--help` and after `--run`: freed space returns to Windows when the VHDX is sparse, otherwise after compacting it (Q26) |
| S22, S59 | `stage shared-helpers`, install-models | Q25: `disk_margin_gb`, `disk_free_gb` and the install-models reading use the smaller of the Linux figure and the Windows drive's. Which drive is **(P8)** |
| S57 | `stage finalize` | Drop "For GPU acceleration (render group), shut Linux down…". The docker-group line says: a new terminal, or `wsl --terminate <distro>` from Windows |

**The opener, as decided (Q19).** One argument, a URL or a path. An existing local path, or a
`file://` URL that names one, is converted with `wslpath -w`. Then it runs
`rundll32.exe url.dll,FileProtocolHandler <target>`, with `rundll32.exe` found by absolute path
through `wslpath` and not through `PATH`. If Windows interop is off or the program is missing, it says
so and exits non-zero; it never falls back to Linux Chrome silently.

**Done when** the setup diff shows these 14 items and stage 1–2's, and
`grep -n 'DEV_ON_CHROMEOS\|garcon\|passwd -d' dev-setup-wsl.sh` finds nothing outside comments and the
refused sections.

### Stage 4: launchers and GUI apps

All in `dev-setup-wsl.sh`. Q20 moves the entries the bundle writes to
`/usr/local/share/applications`, same file names, written with `sudo install -D -m 644`.

| Item | Flag | Edit |
| --- | --- | --- |
| S24 | install-cursor | `cursor.desktop` moves; message says Start menu |
| S26 | install-windsurf | The wrapper keeps `--ozone-platform=x11` and gains `DONT_PROMPT_WSL_INSTALL=1` (Q28). `devin-desktop-x11.desktop` moves. The step that writes a `NoDisplay=true` copy of the stock entry goes: it cannot hide an entry WSLg reads from `/usr/share/applications`. The URL-handler entry stays where it is (it is for `xdg-open`, not the Start menu). The `# v1:` comment records that both entries show, pending the first-run check |
| S28 | install-lazarus | `DARK_DESKTOP` (setup 2927) and the two writes at 3863–3867 move; `lazmode status` reads the same variable, so it follows. Message |
| S30 | install-godot | Both entries move; `Comment=` loses "on Crostini"; message |
| S32 | install-antigravity | The entry moves; message |
| S42 | install-redis, install-mongodb | Four messages say Start menu. Redis Insight and Compass already install into `/usr/share/applications` |

Where the entries' icons live is **(P9)**. An entry in a system folder that points at one user's home
(`Exec=/home/<user>/.local/bin/cursor`) is accepted: the distro has one user.

**Done when** the grep under the additions table finds no bundle launcher still written to
`~/.local/share/applications`, other than the two handler entries (the opener's and Devin's URL
handler).

### Stage 5: test checks

All in `dev-test-wsl.sh`. The test's environment block exports `DONT_PROMPT_WSL_INSTALL=1` (T17), so
`code --version` and the Devin wrapper check do not stop to ask.

**New WSL checks (T8),** in the Base section after the sudo check. `check` fails; `warn` is for what
the user may change:

| Check | Kind |
| --- | --- |
| systemd is running | check |
| The bundle is not under `/mnt/*` | check |
| The sudoers drop-in exists and `visudo -c` passes (with T7, which keeps `sudo -n true` under a new label) | check |
| The opener is in place, and is the handler for https, http and text/html (no live open: it would open tabs) | warn |
| `BROWSER` and `DONT_PROMPT_WSL_INSTALL` are set as a new terminal has them | warn |
| No Windows directory on `PATH` | warn |
| WSLg's X11 and Wayland sockets are present | warn |
| mkcert's CA folder is the one shared from Windows (Q24) | warn |
| INFO lines: WSL version if readable, memory ceiling, swap | info |

**The other items:**

| Items | Section | Edit |
| --- | --- | --- |
| T6 | banner | "Testing Chromebook Linux provisioning" reworded |
| T11 | Base (devmem) | Parse the new label "not accounted for (estimate)" |
| T12 | Base (DDEV) | The router-port check runs unconditionally; labels lose "(ChromeOS passes no 80/443)" |
| T13 | Base (links) | The handler check names the opener's entry instead of `garcon_host_browser.desktop`. Still a WARN |
| T14, T15 | TanStack | Hints reworded (inotify; localhost reaches Windows through localhost forwarding) |
| T18, T20, T45, T46 | Cursor, Lazarus, Godot, Antigravity | Launcher checks look in `/usr/local/share/applications`; labels say Start menu. Cursor's icon check follows **(P9)** |
| T19 | Devin Desktop / Windsurf | X11 entry in the new folder; wrapper has the flag and the variable; the "stock entry hidden" check goes with the step it tested; hints lose "shut Linux down" |
| T21, T22, T27 | Godot | Labels and hints only. The logic already passes on a D3D12 renderer and warns only on llvmpipe or softpipe |
| T23 | Godot | "the Linux VM exposes a GPU (`/dev/dri/renderD*`)" becomes a `/dev/dxg` check, with a hint about the Windows GPU driver and `wsl --update` |
| T24, T25 | Godot | The sommelier and render-group checks are removed |
| T26 | Godot | The GBM check becomes an `eglinfo` check on the Wayland or X11 platform |
| T29 | Android (mobile base) | The `adb connect arc` WARN is removed (Q34a) |
| T32 | Shared services | Two labels say Start menu |
| T35, T36, T41 | Gemma, Local models, OpenClaw | Hints reworded; "(always CPU in Crostini)" dropped |
| T43 | Disk usage by stack | One INFO row and TSV line for the Windows drive's free space (Q25) |

**Done when** `grep -n 'DEV_ON_CHROMEOS\|garcon\|sommelier\|renderD' dev-test-wsl.sh` finds nothing
outside comments and the refused sections.

### Stage 6: init, demo and the remaining text

**Init.**

| Items | Edit |
| --- | --- |
| I5, I7 | Secrets template (new files only): "this laptop"; the agents note loses "8 GB Chromebook" |
| I10 | The render-group todo lines go |
| I12 | Comment: the browser flow works through the Windows browser |
| I14 | The Android section's `adb connect arc` and its three ChromeOS todos become one skip line: no Android device in v1 (Q34a) |
| I15, I19, I21, I24 | Antigravity "Start menu"; Godot's renderer note; the agents notes (Q33); the Lazarus section looks for the dark launcher in the new folder |

**Demo.**

| Items | Edit |
| --- | --- |
| D7 | `demo_open` calls the opener, else `xdg-open`. Every demo page goes through this one function |
| D2, D9 | Header prose; `docker_ok`'s message (a new terminal, or `wsl --terminate <distro>`) |
| D15, D22, D28 | **Content rewrites (Q34c):** the drupal-rag site content, the local-rag corpus and the agents' skill files describe this bundle. Rewrite what is machine-specific: the run order (host script first), memory (the `.wslconfig` ceiling, not "6.4 GB of 8 GB"), inference (CUDA on d1, CPU elsewhere), the helper commands that exist in v1 (no `lan`, `win31` or `wine-com`). Facts that are the same on both platforms stay word for word |
| D11, D23, D26, D32 | Demo strings and the README header lose "Chromebook" |
| D17, D18, D29 | Notes: Godot's renderer; no Android emulator in v1; Compass in the Start menu |

**Setup's remaining text:** S7 (banner), S37 and S50 (disk messages name the Windows side, not
ChromeOS Settings), S48 ("CPU-only in Crostini" becomes per-machine wording), S49 (one message), S56
and S58 (agents notes, finalize hints).

**Done when**, outside the refused sections and inherited comments,
`grep -in 'chromeos\|chromebook\|crostini'` over the four scripts finds only lines that are right to
keep. One class of those is known: text that
describes the *other* machines (an `OLLAMA_REMOTE` hint that says what to do on a Chromebook). List
what remains in the commit message.

### Stage 7: `dev-host-wsl.ps1` and its CI job

New file at the repo root, CRLF (`.gitattributes`), carrying the bundle's version line. It is safe to
rerun: each step checks first and does only what is missing. It is run more than once on purpose,
because one step in the middle is the owner's.

**Steps, in order.**

| # | Step | Notes |
| --- | --- | --- |
| 1 | Checks | Windows 11 22H2 or later; x64; report and stop otherwise |
| 2 | WSL itself | Enable or update it. If Windows needs a restart, say so and stop; the owner reruns |
| 3 | `.wslconfig` | Written **before** the distro exists (Q26). Contents below. How it treats a file that is already there is **(P10)** |
| 4 | Install Debian | Without launching it. If a distro of that name exists, skip; for an existing one, try the sparse conversion only if WSL accepts it without `--allow-unsafe`, else print the manual compaction steps (Q26) |
| 5 | **Stop for the owner** | If the distro has no user account yet (its default user is root), print: open Debian once, create the user, exit, rerun this script. This is Q21's ordering |
| 6 | Check it is Debian 13 | Report and stop if not |
| 7 | `/etc/wsl.conf` | As root: `[boot] systemd=true`, `[interop] appendWindowsPath=false` (Q9). Other keys kept |
| 8 | Bootstrap packages | **(P11)**: whether the script installs `sudo`, `git` and `ca-certificates` as root when the image lacks them |
| 9 | sudoers drop-in | As root: one NOPASSWD line for the user, mode 0440, checked with `visudo -cf` before it is installed and `visudo -c` after (Q7, Q21). File name **(P12)** |
| 10 | mkcert on Windows | `mkcert -install` on Windows, then `CAROOT` as a user environment variable and `CAROOT/up` added to `WSLENV`, keeping what `WSLENV` already holds (Q24). How mkcert gets onto Windows is **(P13)** |
| 11 | Docker Desktop | Check whether its WSL integration is on for this distro; report; change nothing (Q4) |
| 12 | Apply | If `wsl.conf` changed, terminate this distro so it restarts with systemd. Whether the script ever runs `wsl --shutdown` itself is **(P14)** |
| 13 | Report and hand off | One summary block: what was done, what was already in place, what is left. Then the next commands (below) |

**`.wslconfig` contents** (in the Windows user's profile; it applies to every WSL distro on the
laptop):

```ini
[wsl2]
memory=24GB        # about 75% of host RAM: 24GB on the 32 GB laptops, 12GB on the 16 GB ones (Q18)
swap=8GB           # (P10): the value is not settled

[experimental]
sparseVhd=true     # before the distro is installed, so its disk is created sparse (Q26)
```

No `networkingMode` line: v1 keeps the default NAT. No `--allow-unsafe`, ever.

**`/etc/wsl.conf` contents:**

```ini
[boot]
systemd=true

[interop]
appendWindowsPath=false
```

`[interop] enabled` stays at its default (true): the opener needs to start a Windows program.

**Hand-off to init.** The script ends by printing, not doing: open a *new* terminal (so `CAROOT` and
`WSLENV` are in its environment), start Debian, clone the repo into the Linux home (never under
`/mnt`), then `./dev-init-wsl.sh <flags>`, which on its first run only writes the secrets template.

**What it never does:** change Docker Desktop's settings; pass `--allow-unsafe`; set a networking
mode; unregister or reset a distro; touch another distro; store or print a credential.

**PowerShell version and file encoding** are **(P15)**.

**CI, same commit:** a `powershell` job in `lint.yml` on a Windows runner: a parse check of
`dev-host-wsl.ps1`, and PSScriptAnalyzer at Error severity.

### Stage 8: CHANGELOG, README and the version check

- **`CHANGELOG.md`:** five sections (setup, test, init, demo, host), each with a v1 entry. Every entry
  starts "based on dev-setup-chromebook v101" and ends with its ports note. Setup's, test's, init's
  and demo's entries list their WSL edits by decision number; the host script's is "first version".
  Ports notes: the WSL edits are "ports to dev-setup-chromebook: no" (platform edits); the four
  additions to Part B and anything platform-neutral found on the way are called out separately.
- **`README.md`:** the flag tables, forked from the reference README with the five refused flags
  marked "not yet supported on WSL"; the run order with the host script first; "Current version: v1";
  status "built, not yet confirmed run in WSL".
- **AGENTS.md rule 1:** the list of places the version string appears, and the `grep` that must show
  only the new number, from the notes stage 1 kept.
- **The status sentence** in README, AGENTS.md ("Status", "Known open items") and wsl-plan.md changes
  from "planning; nothing is built" to "v1 built, not yet confirmed run in WSL", and wsl-plan.md's
  sequence marks step 5.
- **CI:** port the Chromebook's one-version-number check, extended to five scripts plus the README.
  The Chromebook repo's `tests/` folder is not ported **(P22)**.

### Stage 9: docs

- **`docs/init-checklist.md`**, forked from the reference with targeted WSL edits: the host script and
  the user-creation step in the run order; the WSL sections of each affected stack; sections that
  belong to refused flags kept under a one-line "not in v1" note, as their code is (Q32).
- **`docs/dev-demo.md`**, forked the same way: the opener; the three rewritten demo texts; refused
  demos marked.
- **`docs/wsl-gotchas.md`**, new, the counterpart of `crostini-gotchas.md`. It starts with what is
  already known, each entry in that file's form (what happens, why, the fix): the VM's lifetime and
  `vmIdleTimeout` as a possible lever, marked unverified (Q33); the VHDX, sparse disks and compaction
  (Q26), and `df` reading the virtual size (Q25); never under `/mnt`; CRLF; the Windows PATH (Q9); the
  Start menu's four folders (Q20); VS Code's question (Q28); links and the opener (Q19); mkcert's CA
  shared from Windows (Q24); Docker Desktop (Q4); d4 and AVX (review C2). First-run findings are added
  to it as they are made.

This is the owner's recommendation for stage 9, and this plan agrees with it; **(P16)** asks only
about the refused sections.

## 3. First-run protocol on d3

The first real run of anything in this bundle. The local agent (Claude Code started in d3's WSL
terminal) follows AGENTS.md's local rules: it reads logs by path, and asks before any script or `sudo`
command. Every command below is the owner's to run.

### Sequence

| Step | Where | What | Flags |
| --- | --- | --- | --- |
| 0 | Windows | Get `dev-host-wsl.ps1` from `release/v1` and run it. It stops at step 5 of stage 7's table (or earlier, if Windows needs a restart) | none |
| 1 | Windows | Open Debian once, create the user account and password, exit | |
| 2 | Windows | Run the host script again. It finishes steps 6–13 and prints its summary | none |
| 3 | WSL, new terminal | Read-only checks by hand (below), then clone the repo into the Linux home on `release/v1` | |
| 4 | WSL | **Run A, base only:** init → setup → new terminal → init → test | no flags |
| 5 | WSL | **Run B:** init → setup → new terminal → init → test | `install-all` |
| 6 | WSL | **Run C, the opt-ins, one group at a time:** setup → init → test per group | groups below |
| 7 | WSL | **Refused-list check:** `./dev-setup-wsl.sh install-retro` must stop before anything installs and say why; Run B's output must show the skip notice for install-android-native | |
| 8 | WSL | Optional: `./dev-demo-wsl.sh install-all`, then a few demos by hand | |

Run A comes first because it is short and it is where the platform risks sit: the guard, the preflight,
Docker, Homebrew, DDEV, the opener. A failure there costs minutes, not the hour or more of an
`install-all`. The first init of each run only writes or extends the secrets template; the owner fills
in what he wants set (`MACHINE_LABEL` at least) before the second.

**Run C groups.** Opt-in flags outside `install-all`, grouped so that one failure does not hide the
rest:

| Group | Flags | Note |
| --- | --- | --- |
| C1 | `install-db-server install-ldap-full` | InterBase installs only if the owner's download is in `./assets` (rule 11) |
| C2 | `install-models install-ollama-containers` | About 5 GB of models |
| C3 | `install-elasticsearch install-milvus install-mongodb-atlas-local` | Heavy engines; `devsvc` runs them one at a time |
| C4 | `install-gitlab-runner install-config-mgmt install-cloudflared install-cypress install-asm-arm install-godot-templates` | Three of these manage a systemd service |
| C5 | `install-hermes install-openclaw` | Q33's observation happens here |

Left out unless the owner wants them: `install-oracle-full` (about 13 GB) and `install-ansible-core`
(the lean alternative to what `install-all` already installs).

### Where each C5 check happens

The 15 first-run checks from the review, placed.

| C5 | Check | When | How |
| --- | --- | --- | --- |
| 1 | Is systemd already on in Debian's image? | Step 2 | The host script's summary says whether `wsl.conf` already had it |
| 2 | `dockerd` starts | Run A | `stage docker` in setup; the test's Docker checks |
| 3 | `/tmp` is a tmpfs and WSLg's X11 socket survives | Step 3 | `findmnt /tmp`; `ls -l /tmp/.X11-unix` |
| 4 | What the IPv4 preference check prints | Run A | The `Network:` line in setup's `.output` (Q27) |
| 5 | A D3D12 renderer, not llvmpipe; `/dev/dxg` usable | Step 3, then Run B | `ls -l /dev/dxg`; after Run B, `glxinfo -B` and the test's Godot section |
| 6 | Linux Chrome, an AppImage, Redis Insight and Compass start | Run A (Chrome), Run B | By hand, from the terminal and from the Start menu |
| 7 | The opener: handler, `BROWSER`, a localhost callback, a `file://` path | Run A | `xdg-open https://example.com`; the opener on a local file; init's `gh` and `codex` logins. A long sign-in URL (gcloud) in Run B |
| 8 | A DDEV site opens on 8443 in the Windows browser, with no certificate warning | Run A | A scratch DDEV project by hand, then removed |
| 9 | Cursor's and Devin's scripts and VS Code's question; Devin's stock Start menu entry | Run B | `cursor --version`, the Devin wrapper, both Start menu entries |
| 10 | The Qt5 Lazarus IDE: dialog focus, floating layout, dark palette | Run B | By hand: New Project, Run Parameters, `lazmode dock off`, the dark launcher |
| 11 | The inotify default; `/proc/self/io` | Step 3 | `cat /proc/sys/fs/inotify/max_user_watches`; `test -e /proc/self/io` |
| 12 | `df` on the Windows drive's mount gives a usable figure | Step 3 | `df -h / /mnt/c` |
| 13 | Flatpak apps, a kind cluster, Playwright headed, Cypress | Run B, Run C4 | The test's sections; HandBrake and KDiff3 opened by hand |
| 14 | Ollama and autostarted containers after the last terminal closes | After Run C5 | Close every terminal, wait, reopen: `systemctl status ollama`, `docker ps`, uptime (Q33) |
| 15 | d1: Ollama uses CUDA. d4: the AVX list | Not on d3 | Later machines (section 4) |

Start menu entries may need a `wsl --shutdown` and a new session before they show. Check that before
calling one missing.

### What comes back

- **With the local agent on d3:** nothing is pasted. After each script the agent reads
  `assets/logs/dev-setup-<date-time>.output`, `dev-test-<date-time>.output` and its `.log`,
  `assets/setup-stages.tsv` and the disk TSV, by path.
- **The host script** runs on Windows, outside the agent's reach: the owner pastes its summary block
  into the session. The block is written to be safe to paste (no credentials, no home paths); how it
  is saved is **(P17)**.
- **In a cloud session:** the owner pastes the end of the test run (the summary block and every FAIL
  and WARN line) and the stage summary at the end of setup.
- **Nothing from a run goes into a PR comment** beyond counts, results and repo-relative paths
  (AGENTS.md, "PR comments are public").

**Fixes** found on the way are made on `release/v1` and reported per run. Whether they stay in v1 is
**(P18)**.

## 4. Acceptance

v1 is done when, on d3:

1. Run B (`install-all`) and each Run C group end with **setup: 0 failed, 0 unreached stages** and
   **test: FAIL 0, WARNs only for optional credentials** (AGENTS.md, "Workflow"). A GPU WARN is the
   one foreseeable exception, and it is **(P19)**.
2. The refused-list check (step 7) behaves as decided.
3. The C5 checks that can be made on d3 (1–14) each have a recorded result. A check may come out "does
   not work, documented in the gotchas doc, accepted by the owner"; it may not come out "not looked
   at".
4. `diff -u` against the reference still shows only platform differences, and CI is green.

Then: merge, delete the branch, tag `v1`, publish the GitHub Release with the changelog entry.

**d4.** Q12 says d4 gets a run "before the bundle is called done". Whether that run is part of v1's
acceptance is **(P20)**; the recommendation is that it comes after v1 is tagged.

## 5. Risks

Ordered by how likely each is to block the first run, most likely first. "Blocks" means a run cannot
get past it; "degrades" means the run finishes with something not working.

| # | Risk | Blocks or degrades | What limits it |
| --- | --- | --- | --- |
| 1 | **Debian's WSL image is not what the host script expects:** systemd state, whether `sudo` and `git` are there, how the first launch creates the user, whether it is Debian 13 | Blocks at step 0–2 | The host script checks each and stops with a message. None of this could be confirmed from a source (review, C5 item 1) |
| 2 | **`dockerd` does not start** under the WSL kernel with Debian 13's iptables | Blocks Run A at `stage docker`; everything after depends on it | Older reports needed `iptables-legacy`. Run A finds it in minutes; the fix would be one guarded step |
| 3 | **The scripts have never run.** About 35,600 forked lines, edited in the cloud, checked only by `bash -n` and shellcheck | Blocks wherever a typo sits | Stage 1's rename-only diff, small stages, the per-stage greps, and Run A before Run B |
| 4 | **The preflight stops a good machine:** the Docker Desktop signals (P3), a `PATH` entry under `/mnt` that is legitimate (P2), the guard's interop file under systemd (P1) | Blocks Run A before it starts | The message names the check. Each has a question here |
| 5 | **The opener:** `xdg-open` on Debian 13 may not consult the registered handler under WSL; `rundll32` with a very long sign-in URL | Degrades init's browser logins and demo pages | `BROWSER` is set as well (Q19). Tokens in `secrets.env` avoid the browser |
| 6 | **mkcert's shared CA:** `CAROOT` reaches only processes started after the host script ran, and may not reach a shell started some other way | Degrades: certificate warnings in the Windows browser | The host script says "open a new terminal"; setup reports which CA folder it used (S15); the test warns |
| 7 | **WSLg with systemd:** `/tmp` as tmpfs hiding the X11 socket, or the Wayland socket missing from the runtime directory | Degrades every GUI app and the Godot render test | Checked at step 3, before any install |
| 8 | **Debian 13's Mesa has no d3d12 driver** | Degrades to software rendering; test WARNs | P19. Nothing fails |
| 9 | **Editors:** Cursor's or Devin's script asks VS Code's question; Devin's stock entry crashes; a sign-in that returns through a custom URL scheme (`vscode://`, `windsurf://`) cannot come back from the Windows browser | Degrades the editors | Q28's variable in the wrapper; **(P21)** for the sign-in |
| 10 | **Sparse VHD:** the installed WSL ignores or rejects `sparseVhd`, or the earlier corruption reports still apply | Degrades disk return, or worse | Never `--allow-unsafe`; a new distro holds nothing worth losing on its first day; settings confirmed after the first d3 run (Q26) |
| 11 | **Disk figures:** `df` on the Windows drive's mount is unusable, so the guards fall back to the Linux figure | Degrades the guards to what they are on a Chromebook | P8's fallback |
| 12 | **The VM stops when idle** and takes Ollama and containers with it | Degrades "starts with Linux" | Observed, not fixed, in v1 (Q33) |
| 13 | **The IPv4 preference check** edits `/etc/gai.conf` on every laptop | Neither; a surprise | Harmless; recorded (Q27) |

## 6. Questions for the owner

Each is something the build needs and no decision settles. None is decided here. P1–P9 shape the
bash scripts, P10–P15 and P17 the host script, P16 the docs, P18–P21 the first run and acceptance,
P22–P23 the repo.

- **P1. How the guard detects WSL and WSL 2.** Decided: `$WSL_DISTRO_NAME` or
  `/proc/sys/fs/binfmt_misc/WSLInterop`, and WSL 2 required. Not settled: with systemd on, WSL may
  register its interop under a second name (`WSLInterop-late`; from memory, not confirmed in a source),
  and nothing says how WSL 2 is told from WSL 1. *Recommendation:* accept either interop name, and call
  it WSL 2 when the kernel release contains `WSL2`. Confirm both strings on d3 at step 3.
- **P2. A Windows directory on `PATH`: stop or warn?** The handoff lists it under the preflight; the
  compatibility review says "or a preflight warning". *Recommendation:* stop. The reason for Q9 is that
  a Windows `npm` or `code` can satisfy `command -v` and make setup skip an install without saying so;
  a warning scrolls past. The message names the `wsl.conf` line and the host script.
- **P3. How Docker Desktop's integration is detected.** Not confirmed from a source. *Recommendation:*
  stop only on a positive sign inside the distro (the `docker` command resolving into Docker Desktop's
  shared mount, or its proxy process running here), and treat "cannot tell" as not on. Confirm the
  signs on a laptop that has Docker Desktop before relying on them; if d3 has none, the changelog says
  the check is unverified.
- **P4. The refused flags' one-line reasons.** *Recommendation:* install-lan and install-lan-share:
  "waits for the Tailscale decision (Q8)"; install-android-native: "Android Studio comes later, on
  Windows (Q10)"; install-retro and install-com: "planned for a later version (Q11)".
- **P5. The SSH key comment.** *Recommendation:* `$USER@$(hostname)`. Under WSL the hostname is the
  Windows computer name, which tells the four laptops apart in GitHub's key list. Alternative: a fixed
  `$USER@wsl`.
- **P6. Does setup write `CAROOT` anywhere?** Q24 shares it through `WSLENV`, which reaches shells
  started from Windows. *Recommendation:* no; rely on `WSLENV` as DDEV documents, report the folder in
  use (S15) and let the test warn. Revisit if risk 6 shows up.
- **P7. Names for the opener and its `~/.bashrc` block.** *Recommendation:* `~/.local/bin/dev-open`,
  handler `dev-open.desktop`, block `# >>> dev-setup wsl >>>`, written in base where the Chromebook
  script registers the garcon handler.
- **P8. Which Windows drive the disk helpers read (Q25).** The VHDX's location is not visible from
  inside WSL. *Recommendation:* `/mnt/c` by default, since WSL keeps a distro's disk in the user's
  profile unless told otherwise, with a `DEV_WSL_HOST_DRIVE` override; if the mount is not there, use
  the Linux figure alone and say so once.
- **P9. Launcher icons.** The entries move to a system folder (Q20), but Cursor's, Godot's and
  Antigravity's icons are written under `~/.local/share/icons`, and whether WSLg can read an icon from
  a home directory is unconfirmed. *Recommendation:* write them to `/usr/local/share/pixmaps` and point
  `Icon=` there; check the Start menu on the first run.
- **P10. `.wslconfig`: swap size, and a file that already exists.** Q18 says "adds swap" without a
  figure; `.wslconfig` is shared by every distro on the laptop. *Recommendation:* swap at 25% of host
  RAM (8 GB and 4 GB), which is WSL's own default written down. Set only missing keys; where a key is
  there with another value, leave it and report it, as setup does with DDEV ports the user chose.
- **P11. Does the host script install bootstrap packages?** The drop-in needs `visudo`, which comes
  with `sudo`; cloning needs `git`. Whether Debian's image has them is unconfirmed.
  *Recommendation:* yes: as root, install `sudo`, `git` and `ca-certificates` only when missing. It
  does not clone the repo; it prints the command.
- **P12. The sudoers drop-in's file name.** *Recommendation:* `/etc/sudoers.d/dev-bundle`, one line,
  `<user> ALL=(ALL:ALL) NOPASSWD: ALL`, mode 0440.
- **P13. How mkcert gets onto Windows.** *Recommendation:* use it if present (the native
  dev-setup-windows bundle may have installed it); otherwise install it with `winget`; if `winget` is
  missing, skip the step with a notice and let setup's S15 report say the CA is not shared.
- **P14. Does the host script ever shut WSL down?** A `.wslconfig` change needs `wsl --shutdown`,
  which stops every distro, Docker Desktop's included. *Recommendation:* never on its own. It
  terminates only the Debian distro, and only after it changed `wsl.conf`. For `.wslconfig` it prints
  the command, unless no distro is running.
- **P15. PowerShell version and encoding.** *Recommendation:* written for Windows PowerShell 5.1,
  which every Windows 11 has, and ASCII-only, so 5.1 cannot misread the file's encoding. CI parses it
  under 5.1.
- **P16. Docs: the refused flags' sections.** *Recommendation:* keep them in the forked checklist and
  demo doc under a one-line "not in v1" note, matching Q32 for code, rather than cutting them out and
  putting them back later.
- **P17. The host script's summary.** *Recommendation:* console only, in a form safe to paste; no log
  file on the Windows side in v1.
- **P18. Do fixes found during the d3 runs stay in v1?** AGENTS.md leaves it to the owner.
  *Recommendation:* yes: v1 has never been released, so there is no earlier v1 to protect. Each fix
  gets a dated finding in its comment and a line in the changelog entry.
- **P19. A GPU WARN and acceptance.** If Debian 13's Mesa has no d3d12 driver, the Godot section warns
  about software rendering on every run, and "WARNs only for optional credentials" cannot be met.
  *Recommendation:* accept it for v1 as a recorded known issue, written up in the gotchas doc, and do
  not add a non-Debian Mesa to the bundle.
- **P20. Is d4's run part of v1's acceptance?** *Recommendation:* no. Tag v1 after d3's clean run, as
  AGENTS.md's rule asks for a clean run "on a laptop"; then run d4 (and d1 for CUDA, C5 item 15) with
  per-machine flags, and let what d4 finds go into v2 and the per-machine notes. The release note says
  "confirmed on d3; d4 not yet run", and the bundle is not called done until d4 has run, which is what
  Q12 asks. The alternative, holding the tag for d4, delays v1 for findings that are mostly about AVX
  and would be v2 changes anyway.
- **P21. Editor sign-ins that return through a custom URL scheme.** Sent to the Windows browser, a
  sign-in that ends in `vscode://…` or `windsurf://…` lands on Windows, where nothing handles it. This
  came up while planning; it is not in the review. *Recommendation:* no code in v1. On the first run,
  try each editor's sign-in, note which complete (some poll instead of redirecting, some offer a code
  to paste), and write the working route into the gotchas doc. A Windows-side handler that forwards to
  WSL is a later host-script item.
- **P22. The Chromebook repo's `tests/` folder** (offline helper tests) was not copied into
  `reference/`. *Recommendation:* not ported in v1; decide after the first run which of them would have
  caught something.
- **P23. Confirm the two changes to the stage order** (section 2): the PowerShell CI job in stage 7
  with the script, and setup's leftover text items in stage 6. *Recommendation:* as written.
