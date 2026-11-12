# WSL gotchas

The counterpart of the Chromebook bundle's
[crostini-gotchas.md](../reference/dev-setup-chromebook/docs/crostini-gotchas.md): how Debian 13 on WSL2
differs from a Chromebook's Linux, and what the bundle does about each difference. Every fix is in the
scripts; search them for the flag or the decision number in brackets (Q*n* and P*n* are in
[plans/wsl-plan.md](plans/wsl-plan.md) and [plans/v1-plan.md](plans/v1-plan.md)).

**v1 is built, not yet confirmed run in WSL.** These entries are what was known before the first run:
each says what happens, why, and the fix. An entry marked *unverified* rests on documentation or memory,
not on a laptop. First-run findings are added here as they are made, with the date and the machine.

## The VM and its memory

- **Services stop when the VM does** (`install-ollama`, `devsvc`, `install-ldap-full`, the personal
  agents; Q33). *Unverified: what exactly happens is observed on the first run.*
  WSL runs every distro in one VM. The VM stops some time after the last terminal closes and no process
  holds it, and when Windows sleeps or shuts down. Ollama, the autostarted `devsvc` containers and slapd
  stop with it, so "starts with Linux" means "starts when WSL next starts", and an agent's gateway is not
  reachable around the clock.
  **Fix:** none in v1's code. Record what d3 does after the last terminal closes (`systemctl status
  ollama`, `docker ps`, uptime). `.wslconfig`'s `vmIdleTimeout` under `[wsl2]` is a possible lever
  (*unverified*); the host script does not set it.
- **Memory is a ceiling set on Windows, not a share that shrinks** (`dev-host-wsl.ps1`, `devmem`;
  Q18, Q31, P10).
  WSL gives Linux at most 50% of host RAM by default. A Chromebook's balloon took memory back from
  Linux; WSL has no counterpart, so `devmem`'s residual line is "not accounted for (estimate)" and its
  "ChromeOS has taken back" verdict is gone.
  **Fix:** the host script writes `%USERPROFILE%\.wslconfig`: `memory` at about 75% of host RAM (24GB on
  a 32 GB laptop, 12GB on a 16 GB one) and `swap` at 25%. In a file that is already there it only adds
  missing keys and reports a key that has another value. A change needs `wsl --shutdown`, which stops
  every distro, so the script prints that command and never runs it (P14).
- **The Ollama settings and the CPU-only torch are still sized for 8 GB Chromebooks** (`install-ollama`,
  `install-gemma`; Q30).
  They are forked unchanged in v1. Revisit per machine after benchmarking (Q5).

## Disk

- **`df` inside WSL reads the virtual disk, not the Windows drive** (disk guards in `install-db-server`
  and `install-models`, the test's disk report; Q25, P8). *Unverified: confirm on d3 that `df` on the
  Windows drive's mount gives a usable figure.*
  The distro's disk is a VHDX file with a large virtual size. `df /` reports free space against that
  size, while the Windows drive under it may be nearly full.
  **Fix:** `disk_margin_gb`, `disk_free_gb` and install-models' own reading use the smaller of the Linux
  figure and the Windows drive's. The drive is `/mnt/c` unless `DEV_WSL_HOST_DRIVE` names another; if it
  is not mounted, the Linux figure is used alone and setup says so once. The test's disk report has one
  INFO row for the Windows drive.
- **Space freed in Linux does not return to Windows by itself** (`devclean`, `dev-host-wsl.ps1`; Q26).
  *Unverified on the installed WSL version.*
  A VHDX grows and does not shrink unless it is sparse or is compacted.
  **Fix:** the host script writes `sparseVhd=true` under `[experimental]` in `.wslconfig` *before* it
  installs the distro, so the new disk is created sparse. For a distro that already exists it tries
  `wsl --manage <distro> --set-sparse true` only where WSL accepts that without `--allow-unsafe`, which
  the bundle never passes. Otherwise compact by hand: `wsl --shutdown`, then `Optimize-VHD -Mode Full`
  on the distro's `ext4.vhdx`, or in `diskpart`: `select vdisk file=...`, `attach vdisk readonly`,
  `compact vdisk`, `detach vdisk`. `devclean --help` and `devclean --run` carry a one-line reminder.

## Where the bundle lives, and line endings

- **Never under `/mnt`** (preflight, test; Q29).
  On the Windows filesystem exec bits, setuid sandboxes, pipx and venv paths break, and it is slow.
  **Fix:** clone into the Linux home. Setup's preflight stops when the bundle's folder is under
  `/mnt/*`, and the test fails the same check.
- **CRLF line endings** (preflight; `.gitattributes`).
  A script that passed through Windows Git or a Windows editor fails with `$'\r': command not found`.
  **Fix:** `.gitattributes` keeps every text file LF (`*.ps1` is CRLF). Setup's preflight looks for CR
  line endings in the `dev-*.sh` files next to it and names them. One limit: a script cannot check
  itself, because bash fails on its first line before any check runs.

## Windows and Linux side by side

- **A Windows `npm` or `code` on `PATH` hides a missing Linux one** (`dev-host-wsl.ps1`, preflight,
  test; Q9, P2).
  WSL appends the Windows `PATH` by default, so `command -v npm` can succeed with no Linux npm, and
  setup would skip an install without saying so.
  **Fix:** the host script sets `appendWindowsPath=false` under `[interop]` in `/etc/wsl.conf`. Setup's
  preflight stops while a Windows directory is on `PATH`; the test warns. `[interop] enabled` stays
  true: the link opener starts a Windows program.
- **systemd is not on by default** (`dev-host-wsl.ps1`, preflight, test). *Unverified: whether Debian's
  WSL image has it on is the first thing the host script's summary shows.*
  Docker, kind, Langfuse and Ollama's service need it.
  **Fix:** the host script sets `[boot] systemd=true` in `/etc/wsl.conf` and terminates the distro so it
  restarts with systemd. Setup's preflight stops when systemd is not running.
- **sudo asks for a password** (`dev-host-wsl.ps1`, preflight, test; Q7, Q21, P12).
  On a Chromebook the bundle removed the Linux user's password. Under WSL the account keeps it.
  **Fix:** the host script writes `/etc/sudoers.d/dev-bundle`, one `NOPASSWD` line for the user, mode
  0440, checked with `visudo`. It can only do so after the user account exists, and Debian creates that
  account at its first launch, so the host script is run twice with that step of yours in between. The
  file name has no dot on purpose: sudo skips files in `/etc/sudoers.d/` whose names contain one.
- **Docker Desktop's WSL integration conflicts with docker-ce in the distro** (preflight,
  `dev-host-wsl.ps1`; Q4, P3). *Unverified: the signs both scripts look for have not been seen on a
  laptop with Docker Desktop.*
  **Fix:** the bundle uses docker-ce inside the distro. The host script reads Docker Desktop's settings
  and reports; it changes nothing there. Setup's preflight stops on a positive sign inside the distro:
  the `docker` command resolving into Docker Desktop's shared mount, or its proxy process running there.
  Turn the integration off for this distro in Docker Desktop: Settings > Resources > WSL integration.
- **mkcert's CA must be shared, or the Windows browser warns on DDEV's sites** (`dev-host-wsl.ps1`,
  `stage homebrew`, test; Q24, P6, P13). *Unverified end to end.*
  The browser is on Windows; a CA made inside Linux is unknown to it.
  **Fix:** DDEV's documented route. The host script runs `mkcert -install` on Windows, then sets `CAROOT`
  and adds `CAROOT/up` to `WSLENV`, so mkcert inside WSL uses the same CA. `CAROOT` reaches only shells
  started after that, which is why the host script says "open a new terminal". Setup reports which CA
  folder it used; the test warns when it is not the shared one. If setup ran first with a Linux-only
  CA: run the host script, open a new terminal, rerun setup, then `ddev poweroff` and start the project
  again so its certificate is made from the shared CA.

## Links, browsers and sign-ins

- **Links from Linux open in the Windows default browser** (`stage chrome`, `demo_open`, `ldap ui`;
  Q19, P7). *Unverified: that `xdg-open` on Debian 13 honours the handler under WSL, a very long sign-in
  link, and a `file://` path.*
  There is no garcon under WSL, and the bundle does not use `wslu`.
  **Fix:** setup writes its own opener, `~/.local/bin/dev-open`. It takes one URL or path, turns an
  existing local path into a Windows one with `wslpath -w`, and calls `rundll32.exe
  url.dll,FileProtocolHandler` by absolute path, so it works with the Windows `PATH` left out. Its
  handler entry `dev-open.desktop` is registered with `xdg-mime`, and a marked `~/.bashrc` block sets
  `BROWSER` for tools that read only that. If Windows interop is off it says so and exits non-zero; it
  never falls back to Linux Chrome. Back to Linux Chrome: `xdg-mime default com.google.Chrome.desktop
  x-scheme-handler/https x-scheme-handler/http text/html`.
- **A browser on Windows reaches a server in WSL at `localhost`** (DDEV, dev servers; Q17).
  v1 keeps WSL's default NAT networking, and Windows forwards `localhost` ports to WSL. DDEV sites are
  `https://<site>.ddev.site:8443`: the bundle keeps 8080/8443 for parity with the Chromebooks, not
  because of a forwarding limit. Reaching WSL from another laptop is not in v1 (Q8).
- **Editor sign-ins that return through a custom URL scheme** (`install-vscode`, `install-cursor`,
  `install-windsurf`; P21). *Unverified: each editor's sign-in is tried on the first run and the working
  route is written here.*
  Sent to the Windows browser, a sign-in that ends in `vscode://...` or `windsurf://...` lands on
  Windows, where nothing hands it back to the editor in WSL. Some sign-ins poll instead of redirecting,
  and some offer a code to paste. If a native Windows VS Code is installed on the same laptop (for
  example by dev-setup-windows), a `vscode://` sign-in link opens that Windows editor and not the one in
  WSL.
  **Fix:** none in v1's code. A Windows-side handler that forwards to WSL is a later host-script item.
- **VS Code's question under WSL** (`install-vscode`, `install-windsurf`, test; Q28).
  `code` started inside WSL stops to ask whether you meant the Windows build.
  **Fix:** `DONT_PROMPT_WSL_INSTALL=1` in the marked `~/.bashrc` block, in the test's environment and in
  the Devin wrapper. *Unverified: whether Cursor's and Devin's launcher scripts carry the same
  question.*

## GUI apps and the GPU

- **The Start menu lists only four folders** (launchers for Cursor, Devin, Lazarus, Godot, Antigravity;
  Q20, P9).
  WSLg shows a Linux app in the Windows Start menu when its `.desktop` file is in
  `/usr/share/applications`, `/usr/local/share/applications`, snap's folder or Flatpak's exports. It does
  not read `~/.local/share/applications`, where the Chromebook bundle wrote its entries.
  **Fix:** the bundle's launcher entries go to `/usr/local/share/applications` and their icons to
  `/usr/local/share/pixmaps`, written with `sudo install`. A new entry can need `wsl --shutdown` and a
  new session before it shows: check that before calling one missing. Devin's stock entry can no longer
  be hidden, so both "Devin" and "Devin (X11)" show; use "Devin (X11)".
- **The GPU is `/dev/dxg`, not a render node** (`install-godot`, the test's Godot section; P19).
  *Unverified: whether Debian 13's Mesa has the d3d12 driver.*
  WSLg gives OpenGL through Mesa's D3D12 driver. There is no virgl, no `/dev/dri/renderD128`, no
  sommelier and no `render` group, so setup adds no groups and the test checks `/dev/dxg`, `eglinfo` and
  `glxinfo` instead. If Mesa has no d3d12 driver, rendering falls back to llvmpipe and the test's Godot
  section warns about software rendering.
  **Fix:** none; that WARN is accepted for v1 as a known issue, and no non-Debian Mesa is added.
- **WSLg's sockets under systemd** (test). *Unverified.*
  With systemd on, a tmpfs on `/tmp` can hide `/tmp/.X11-unix`, and the Wayland socket may be missing
  from the runtime directory. Every GUI app then fails to open a window.
  **Fix:** the test warns when either socket is missing. `wsl --shutdown` and a new session, or `wsl
  --update`, are the first things to try.

## Machines

- **d4 has no AVX** (per-machine flags; Q12, Q14, review C2).
  The Pentium Silver N5030 has no AVX or AVX2. MongoDB 5 and later need AVX, so `install-mongodb` and
  `install-mongodb-atlas-local` cannot run there, and other prebuilt engines and wheels may refuse too.
  **Fix:** one bundle, no tiers: choose flags per machine. d4 gets its own run before the bundle is
  called done, and what it finds is listed here.
- **Not in v1** (the refused flags; Q13).
  install-lan and install-lan-share wait for the Tailscale decision (Q8); install-android-native waits
  for Android Studio on Windows (Q10); install-retro and install-com are planned for a later version
  (Q11). Naming one stops the run before anything installs; a group that contains one skips it with a
  notice.
