# Changelog

The bundle's version history: one section per script, newest version first. The WSL bundle is five
scripts that share one version number: `dev-setup-wsl.sh`, `dev-test-wsl.sh`, `dev-init-wsl.sh`,
`dev-demo-wsl.sh` and the Windows host script `dev-host-wsl.ps1`. A change to any of them bumps all
five, so a version can appear under a script with no change of its own ("version bump only").

Numbering starts at v1. **v1 is based on dev-setup-chromebook v101** (`68113ff`, copied into
`reference/dev-setup-chromebook/`); the history before that is in that bundle's
[CHANGELOG](reference/dev-setup-chromebook/CHANGELOG.md).

Each entry ends with a ports note: whether the change applies to
[dev-setup-chromebook](https://github.com/dhouse109/dev-setup-chromebook) too (yes / no / n.a.). Fixes
are ported between the two bundles by hand.

Decision numbers (Q*n*, P*n*) point at [docs/plans/wsl-plan.md](docs/plans/wsl-plan.md), "Decisions so
far", and [docs/plans/v1-plan.md](docs/plans/v1-plan.md), section 6. Item numbers (S, T, I, D) point at
the inventory in [docs/plans/v1-wsl-review.md](docs/plans/v1-wsl-review.md), Part B.

## dev-setup-wsl

The installer: it sets up each stack the flags name. Newest version first.

- **v1** (built in the cloud, not yet confirmed run in WSL):
  - Based on dev-setup-chromebook v101: a straight fork of `dev-setup-chromebook.sh` with the WSL edits
    below and nothing else. Same flags, section order and headings.
  - Host guard: Debian on WSL2 instead of ChromeOS. `DEV_ON_WSL` from `$WSL_DISTRO_NAME` or either
    interop file (`WSLInterop`, `WSLInterop-late`); WSL 2 required, read from the kernel release; the
    `DEV_BUNDLE_ANY_HOST` name and wording kept (Q22, Q23, P1).
  - Preflight, new, between the guard and the screen-output block, so a refused run writes nothing:
    not root; not under `/mnt/*`; no CR line endings in the sibling scripts; systemd running; no
    Windows directory on `PATH`; Docker Desktop's WSL integration not on; `sudo -n true`; Debian 13
    (warn only) (Q29, Q4, P2, P3). The two Docker Desktop signs are unverified until a laptop with
    Docker Desktop shows them.
  - The "not yet supported on WSL" list: install-lan, install-lan-share, install-android-native,
    install-retro, install-com. Named directly, a flag stops the run before anything installs; brought
    in by a group, it is skipped with a notice. Their code is forked untouched (Q13, Q32, P4).
  - `stage system`: no `passwd -d`; sudo is passwordless through the host script's drop-in (Q7, Q21).
  - `stage ssh`: the key comment names the machine, `$USER@$(hostname)` (P5).
  - `stage docker`: no `video` / `render` groups; WSLg's GPU is `/dev/dxg`.
  - `stage homebrew`: DDEV's router moves to 8080/8443 on every machine (Q17). A report of whether
    mkcert's CA is the one shared from Windows replaces the ChromeOS import instructions (Q24, P6).
  - `stage chrome`: links open in the Windows default browser through the bundle's own opener,
    `~/.local/bin/dev-open`, its handler entry `dev-open.desktop`, and a marked `~/.bashrc` block that
    exports `BROWSER` and `DONT_PROMPT_WSL_INSTALL=1` (Q19, Q28, P7). `ldap ui` uses the opener.
  - `devmem`: the residual is "not accounted for (estimate)"; the "ChromeOS has taken back" verdict
    is gone (Q31). `devclean`: one note about the VHDX and compaction (Q26).
  - Disk guards (`disk_margin_gb`, `disk_free_gb`, install-models) use the smaller of the Linux
    figure and the Windows drive's; `DEV_WSL_HOST_DRIVE` names a drive other than `/mnt/c` (Q25, P8).
  - Launchers for Cursor, Devin (X11), Lazarus (Dark), Godot and Antigravity go to
    `/usr/local/share/applications`, their icons to `/usr/local/share/pixmaps` (Q20, P9). The Devin
    wrapper also sets `DONT_PROMPT_WSL_INSTALL=1`; the stock Devin entry is no longer hidden.
  - Messages reworded: banner, disk hints (Linux and the Windows drive), per-machine inference,
    Start menu, the agents notes, the finalize hints (Q30, Q33).
  - Ports to dev-setup-chromebook: no (platform edits). Called out separately: the review's addition
    S59 (install-models' own `df` reading) is a WSL edit too, so it does not port either.

## dev-test-wsl

The referee: it checks that every installed component works, and writes the disk report. Newest
version first.

- **v1** (built in the cloud, not yet confirmed run in WSL):
  - Based on dev-setup-chromebook v101: a straight fork of `dev-test-chromebook.sh` with the WSL
    edits below. The host guard and the refused list are the same blocks as in setup.
  - New WSL checks in the Base section. FAIL: passwordless sudo, the drop-in
    `/etc/sudoers.d/dev-bundle` with `visudo -c`, systemd running, the bundle not under `/mnt`.
    WARN: no Windows directory on `PATH`, the opener in place, `BROWSER` and
    `DONT_PROMPT_WSL_INSTALL` in `~/.bashrc`, WSLg's X11 and Wayland sockets, mkcert's CA shared from
    Windows. INFO: WSL version, kernel, memory ceiling and swap (Q7, Q9, Q19, Q21, Q24, Q28).
  - The environment block exports `DONT_PROMPT_WSL_INSTALL=1` (Q28).
  - `devmem`'s new label; DDEV's router-port check on every machine (Q17); the link-handler check
    names `dev-open.desktop` (Q19).
  - Launcher checks look in `/usr/local/share/applications` (Q20, P9); the Devin check wants the
    flag and the variable in the wrapper, and the "stock entry hidden" check is gone.
  - Godot: the render-node check becomes a `/dev/dxg` check; the sommelier and render-group checks
    are removed; the GBM check becomes an `eglinfo` check on Wayland or X11; labels and hints.
  - The `adb connect arc` WARN is removed (Q34a). Hints reworded. The disk report gains one INFO row
    and TSV line for the Windows drive's free space (Q25).
  - Ports to dev-setup-chromebook: no (platform edits). Called out separately: T45 and T46, the two
    launcher checks the review missed, follow Q20 and do not port.

## dev-init-wsl

Logins, API keys and config, read from `~/.config/dev-init/secrets.env`. Newest version first.

- **v1** (built in the cloud, not yet confirmed run in WSL):
  - Based on dev-setup-chromebook v101: a straight fork of `dev-init-chromebook.sh` with the WSL
    edits below. The host guard and the refused list are the same blocks as in setup.
  - Secrets template (new files only): "this laptop"; the agents note.
  - The render-group todo lines are gone. The Android section's `adb connect arc` and its three
    ChromeOS todos are one skip line: no Android device in v1 (Q10, Q34a).
  - Browser logins go through the Windows browser (Q19). Antigravity "Start menu"; Godot's renderer
    note; the agents comments (Q30, Q33).
  - Ports to dev-setup-chromebook: no (platform edits). Called out separately: I24, the Lazarus
    section's launcher path the review missed, follows Q20 and does not port.

## dev-demo-wsl

Optional hands-on demos, installed into `~/dev-demo`. Newest version first.

- **v1** (built in the cloud, not yet confirmed run in WSL):
  - Based on dev-setup-chromebook v101: a straight fork of `dev-demo-chromebook.sh` with the WSL
    edits below. The host guard and the refused list are the same blocks as in setup.
  - `demo_open` calls the bundle's opener, else `xdg-open` (Q19). `docker_ok`'s message.
  - Content rewritten for this bundle (Q34c): the drupal-rag site content, the local-rag corpus and
    the agents' skill files say host script first, five scripts, the `.wslconfig` memory ceiling,
    CUDA or CPU per laptop, and only the helper commands that exist in v1.
  - Demo strings and notes reworded (the README header, Godot's renderer, no Android emulator in v1,
    Compass in the Start menu).
  - Ports to dev-setup-chromebook: no (platform edits).

## dev-host-wsl

The Windows host script (PowerShell). It runs first, on Windows, and has no Chromebook counterpart.
Newest version first.

- **v1** (built in the cloud, not yet confirmed run on Windows):
  - Based on dev-setup-chromebook v101 as the rest of the bundle is; first version of this script.
  - Thirteen steps, each safe to rerun: checks (Windows 11 22H2 or later, x64); WSL; `.wslconfig`
    (memory about 75% of host RAM, swap 25%, `sparseVhd=true`, before the distro exists); Debian
    installed without launching it; a stop for the owner to create the Linux user; the Debian 13
    check; `/etc/wsl.conf` (`systemd=true`, `appendWindowsPath=false`); bootstrap packages; the sudoers
    drop-in `/etc/sudoers.d/dev-bundle`; mkcert on Windows with `CAROOT` shared through `WSLENV`; the
    Docker Desktop check (report only); apply; one summary block and the next commands
    (Q3, Q4, Q7, Q9, Q18, Q21, Q24, Q26, P10 to P15, P17).
  - Ports to dev-setup-chromebook: n.a.
