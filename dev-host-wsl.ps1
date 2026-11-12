# dev-host-wsl - Version 1
# Version history: CHANGELOG.md, next to this script in the bundle (one section per script).
#
# The Windows half of dev-setup-windows-wsl. It runs FIRST, on Windows, and prepares Debian 13 on WSL2 for
# the four bash scripts (dev-init-wsl.sh, dev-setup-wsl.sh, dev-test-wsl.sh, dev-demo-wsl.sh), which run
# inside the distro. It has no Chromebook counterpart. The build spec is docs/plans/v1-plan.md, stage 7.
#
# Run it from a PowerShell window in the folder that holds it:
#     powershell -ExecutionPolicy Bypass -File .\dev-host-wsl.ps1
# No flags. It is safe to rerun: each step checks first and does only what is missing. It is run more than
# once on purpose, because one step in the middle is yours: creating the Linux user (step 5).
#
# Steps, in order:
#    1  checks: Windows 11 22H2 or later, x64
#    2  WSL itself: enabled, updated (stops if Windows needs a restart)
#    3  %USERPROFILE%\.wslconfig: memory, swap, sparseVhd, written BEFORE the distro exists (Q18, Q26, P10)
#    4  Debian installed, without launching it
#    5  STOPS for you if the distro has no user account yet: open Debian once, create the user, rerun (Q21)
#    6  the distro is Debian 13
#    7  /etc/wsl.conf: [boot] systemd=true, [interop] appendWindowsPath=false (Q9)
#    8  bootstrap packages, as root, only when missing: sudo, git, ca-certificates (P11)
#    9  the sudoers drop-in /etc/sudoers.d/dev-bundle, checked with visudo (Q7, Q21, P12)
#   10  mkcert on Windows; CAROOT shared into WSL through WSLENV (Q24, P13)
#   11  Docker Desktop: checks its WSL integration for this distro and reports; changes nothing (Q4)
#   12  apply: terminates this distro if wsl.conf changed; never runs 'wsl --shutdown' on its own (P14)
#   13  one summary block, then the next commands
#
# What it never does: change Docker Desktop's settings; pass --allow-unsafe; set a networking mode;
# unregister or reset a distro; touch another distro; store or print a credential.
#
# v1: written for Windows PowerShell 5.1, which every Windows 11 has, and ASCII-only, so 5.1 cannot misread
# the file's encoding (P15). The summary goes to the console only and is safe to paste: no credentials, no
# user names, no home paths (P17).
# v1: nothing here has run on a laptop yet. What could not be confirmed from a source is marked
# "to confirm on the first run" where it is used.

$ErrorActionPreference = 'Stop'

$DistroName = 'Debian'
$DropInPath = '/etc/sudoers.d/dev-bundle'

$script:Done = New-Object System.Collections.ArrayList
$script:Already = New-Object System.Collections.ArrayList
$script:Left = New-Object System.Collections.ArrayList
$script:WslConfChanged = $false
$script:WslConfigChanged = $false

$script:WslExe = Join-Path $env:SystemRoot 'System32\wsl.exe'
if (-not (Test-Path $script:WslExe)) {
    # A 32-bit PowerShell on 64-bit Windows sees System32 redirected.
    $script:WslExe = Join-Path $env:SystemRoot 'Sysnative\wsl.exe'
}
# wsl.exe prints UTF-16 by default, which arrives here with a NUL after every character. Newer WSL prints
# UTF-8 with this variable set; Invoke-Wsl strips NULs as well, for the versions that ignore it.
$env:WSL_UTF8 = '1'

function Add-Done { param([string]$Text) [void]$script:Done.Add($Text); Write-Host ('  done: ' + $Text) }
function Add-Already { param([string]$Text) [void]$script:Already.Add($Text); Write-Host ('  already in place: ' + $Text) }
function Add-Left { param([string]$Text) [void]$script:Left.Add($Text); Write-Host ('  left for you: ' + $Text) }
function Write-Step { param([int]$Number, [string]$Title) Write-Host ''; Write-Host ('[step ' + $Number + '] ' + $Title) }

function Show-Summary {
    Write-Host ''
    Write-Host '================================================================='
    Write-Host 'Host script summary (Version 1)'
    Write-Host 'Done in this run:'
    if ($script:Done.Count -eq 0) { Write-Host '  nothing' }
    foreach ($line in $script:Done) { Write-Host ('  - ' + $line) }
    Write-Host 'Already in place:'
    if ($script:Already.Count -eq 0) { Write-Host '  nothing' }
    foreach ($line in $script:Already) { Write-Host ('  - ' + $line) }
    Write-Host 'Left for you:'
    if ($script:Left.Count -eq 0) { Write-Host '  nothing' }
    foreach ($line in $script:Left) { Write-Host ('  - ' + $line) }
    Write-Host '================================================================='
}

function Stop-Script {
    # Prints the summary so far, then the reason, and ends. Code 2: something is yours to do, then rerun.
    # Code 1: a step failed.
    param([string[]]$Message, [int]$Code = 2)
    Show-Summary
    Write-Host ''
    foreach ($line in $Message) { Write-Host $line }
    exit $Code
}

function Invoke-Wsl {
    # Runs wsl.exe and returns its exit code and its output as clean lines. Native stderr is not allowed
    # to become a terminating error (Windows PowerShell 5.1 does that under ErrorActionPreference Stop).
    param([string[]]$Arguments)
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & $script:WslExe @Arguments 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $old
    $lines = @()
    foreach ($item in @($raw)) {
        if ($null -ne $item) {
            $text = ("$item" -replace "`0", '').TrimEnd("`r")
            if ($text.Trim() -ne '') { $lines += $text }
        }
    }
    return New-Object PSObject -Property @{ Code = $code; Lines = $lines }
}

function Invoke-Distro {
    # Runs a small sh script inside the distro. The script travels as base64, so no quote, dollar sign or
    # line ending of it has to survive two command lines.
    param([string]$Script, [string]$User = 'root')
    $lf = ($Script -replace "`r`n", "`n")
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($lf))
    return Invoke-Wsl -Arguments @('-d', $DistroName, '-u', $User, '-e', 'sh', '-c', "echo $b64 | base64 -d | sh")
}

function Get-DistroRecord {
    # WSL keeps one registry key per registered distro. Read-only.
    param([string]$Name)
    $root = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'
    if (-not (Test-Path $root)) { return $null }
    $defaultGuid = ''
    $rootProps = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue
    if ($null -ne $rootProps -and $null -ne $rootProps.PSObject.Properties['DefaultDistribution']) {
        $defaultGuid = [string]$rootProps.DefaultDistribution
    }
    foreach ($key in @(Get-ChildItem -Path $root -ErrorAction SilentlyContinue)) {
        $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
        if ($null -eq $props) { continue }
        if ($null -eq $props.PSObject.Properties['DistributionName']) { continue }
        if ([string]$props.DistributionName -ne $Name) { continue }
        $basePath = ''
        if ($null -ne $props.PSObject.Properties['BasePath']) { $basePath = [string]$props.BasePath }
        if ($basePath.StartsWith('\\?\')) { $basePath = $basePath.Substring(4) }
        $wslVersion = 0
        if ($null -ne $props.PSObject.Properties['Version']) { $wslVersion = [int]$props.Version }
        return New-Object PSObject -Property @{
            Guid = $key.PSChildName
            BasePath = $basePath
            WslVersion = $wslVersion
            IsDefault = ($key.PSChildName -eq $defaultGuid)
        }
    }
    return $null
}

function Test-DistroRunning {
    param([string]$Name)
    $r = Invoke-Wsl -Arguments @('-l', '--running', '-q')
    foreach ($line in $r.Lines) { if ($line.Trim() -eq $Name) { return $true } }
    return $false
}

function Test-AnyDistroRunning {
    # 'wsl -l --running -q' prints a sentence, not a name, when nothing runs; its exit code is then not 0.
    $r = Invoke-Wsl -Arguments @('-l', '--running', '-q')
    return ($r.Code -eq 0 -and $r.Lines.Count -gt 0)
}

function Set-IniValues {
    # Sets keys in INI text held as lines. Force = $false: only missing keys are added; a key that is there
    # with another value is left alone and reported (P10). Force = $true: the value is replaced.
    # Every other line is kept as it is.
    param([string[]]$Lines, [object[]]$Wanted, [bool]$Force)
    $list = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in @($Lines)) { if ($null -ne $l) { $list.Add([string]$l) } }
    $notes = @()
    $changed = $false
    foreach ($w in $Wanted) {
        $secStart = -1
        $secEnd = $list.Count
        for ($i = 0; $i -lt $list.Count; $i++) {
            $t = $list[$i].Trim()
            if ($t -match '^\[(.+)\]$') {
                if ($secStart -ge 0) { $secEnd = $i; break }
                if ($Matches[1].Trim() -ieq $w.Section) { $secStart = $i }
            }
        }
        $newLine = $w.Key + '=' + $w.Value
        if ($secStart -lt 0) {
            if ($list.Count -gt 0 -and $list[$list.Count - 1].Trim() -ne '') { $list.Add('') }
            $list.Add('[' + $w.Section + ']')
            $list.Add($newLine)
            $changed = $true
            $notes += New-Object PSObject -Property @{ Key = $w.Key; State = 'added'; Current = $w.Value }
            continue
        }
        $found = -1
        $current = ''
        for ($i = $secStart + 1; $i -lt $secEnd; $i++) {
            if ($list[$i] -match '^\s*([^#;=\s][^=]*?)\s*=\s*(.*?)\s*$') {
                if ($Matches[1] -ieq $w.Key) { $found = $i; $current = $Matches[2]; break }
            }
        }
        if ($found -ge 0) {
            if ($current -ieq $w.Value) {
                $notes += New-Object PSObject -Property @{ Key = $w.Key; State = 'already'; Current = $current }
            } elseif ($Force) {
                $list[$found] = $newLine
                $changed = $true
                $notes += New-Object PSObject -Property @{ Key = $w.Key; State = 'changed'; Current = $current }
            } else {
                $notes += New-Object PSObject -Property @{ Key = $w.Key; State = 'differs'; Current = $current }
            }
        } else {
            $insertAt = $secEnd
            while ($insertAt -gt ($secStart + 1) -and $list[$insertAt - 1].Trim() -eq '') { $insertAt-- }
            $list.Insert($insertAt, $newLine)
            $changed = $true
            $notes += New-Object PSObject -Property @{ Key = $w.Key; State = 'added'; Current = $w.Value }
        }
    }
    return New-Object PSObject -Property @{ Lines = $list.ToArray(); Changed = $changed; Notes = $notes }
}

function Get-JsonValue {
    # A property of a ConvertFrom-Json object under either of two spellings, or $null.
    param($Object, [string[]]$Names)
    if ($null -eq $Object) { return $null }
    foreach ($n in $Names) {
        $p = $Object.PSObject.Properties[$n]
        if ($null -ne $p) { return $p.Value }
    }
    return $null
}

Write-Host 'dev-host-wsl - Version 1'
Write-Host 'Prepares Debian 13 on WSL2 for the dev bundle. Safe to rerun.'

# ---------------------------------------------------------------------------------------------------
Write-Step 1 'Checks: Windows 11 22H2 or later, x64'
$build = [Environment]::OSVersion.Version.Build
$arch = $env:PROCESSOR_ARCHITECTURE
if ($null -ne $env:PROCESSOR_ARCHITEW6432 -and $env:PROCESSOR_ARCHITEW6432 -ne '') { $arch = $env:PROCESSOR_ARCHITEW6432 }
# Windows 11 22H2 is build 22621. The minimum is stated for when mirrored networking comes (Q8).
if ($build -lt 22621) {
    Stop-Script -Code 1 -Message @(
        ('This is Windows build ' + $build + '. The bundle needs Windows 11 22H2 (build 22621) or later.'),
        'Nothing was changed.')
}
if ($arch -ne 'AMD64') {
    Stop-Script -Code 1 -Message @(
        ('This is a ' + $arch + ' Windows. The bundle is x64 only.'),
        'Nothing was changed.')
}
if (-not (Test-Path $script:WslExe)) {
    Stop-Script -Code 1 -Message @('wsl.exe was not found in the Windows folder.', 'Nothing was changed.')
}
Add-Already ('Windows build ' + $build + ', x64')

# ---------------------------------------------------------------------------------------------------
Write-Step 2 'WSL itself'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = (New-Object Security.Principal.WindowsPrincipal($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$ver = Invoke-Wsl -Arguments @('--version')
$status = Invoke-Wsl -Arguments @('--status')
if ($ver.Code -eq 0 -and $status.Code -eq 0) {
    Add-Already 'WSL is installed'
    # Updating is quick when WSL is current. A failure here (no network, a declined prompt) is not fatal.
    $upd = Invoke-Wsl -Arguments @('--update')
    if ($upd.Code -eq 0) { Add-Already 'WSL is up to date (wsl --update)' }
    else { Add-Left 'wsl --update did not finish; run it by hand when the network is there' }
} else {
    if (-not $isAdmin) {
        Stop-Script -Message @(
            'WSL is not installed or not complete, and enabling it needs administrator rights.',
            'Open PowerShell with "Run as administrator", run this script once there, then go on in a',
            'normal PowerShell window.')
    }
    Write-Host '  enabling WSL (wsl --install --no-distribution) ...'
    $inst = Invoke-Wsl -Arguments @('--install', '--no-distribution')
    foreach ($line in $inst.Lines) { Write-Host ('    ' + $line) }
    if ($inst.Code -ne 0) {
        Stop-Script -Code 1 -Message @(
            ('wsl --install --no-distribution failed (exit ' + $inst.Code + ').'),
            'See its output above. Nothing else was changed.')
    }
    Add-Done 'WSL enabled (wsl --install --no-distribution)'
    $status = Invoke-Wsl -Arguments @('--status')
    if ($status.Code -ne 0) {
        Stop-Script -Message @(
            'Windows needs a restart before WSL works.',
            'Restart Windows, then run this script again.')
    }
}
[void](Invoke-Wsl -Arguments @('--set-default-version', '2'))

# ---------------------------------------------------------------------------------------------------
Write-Step 3 '.wslconfig (before the distro exists)'
# v1 (Q18, P10): memory is about 75% of host RAM, 24GB on the 32 GB laptops and 12GB on the 16 GB ones.
# Swap is 25% of host RAM, WSL's own default written down: 8GB and 4GB. sparseVhd=true goes in before the
# distro is installed, so its disk is created sparse and freed space returns to Windows (Q26).
# No networkingMode line: v1 keeps the default NAT. .wslconfig applies to every WSL distro on the laptop,
# so in a file that is already there only missing keys are added; a key with another value is left alone
# and reported (P10).
$ramGb = [int][math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$memGb = [int][math]::Floor($ramGb * 0.75)
$swapGb = [int][math]::Floor($ramGb * 0.25)
if ($memGb -lt 1) { $memGb = 1 }
if ($swapGb -lt 1) { $swapGb = 1 }
$wslConfigPath = Join-Path $env:USERPROFILE '.wslconfig'
$wanted = @(
    @{ Section = 'wsl2'; Key = 'memory'; Value = ($memGb.ToString() + 'GB') },
    @{ Section = 'wsl2'; Key = 'swap'; Value = ($swapGb.ToString() + 'GB') },
    @{ Section = 'experimental'; Key = 'sparseVhd'; Value = 'true' }
)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if (-not (Test-Path $wslConfigPath)) {
    $new = @(
        '# Written by dev-host-wsl.ps1 (dev-setup-windows-wsl v1). It applies to every WSL distro on this laptop.',
        '# memory: about 75% of host RAM. swap: 25% of host RAM, WSL''s own default written down.',
        '[wsl2]',
        ('memory=' + $memGb + 'GB'),
        ('swap=' + $swapGb + 'GB'),
        '',
        '# sparseVhd: a new distro''s disk is created sparse, so space freed in Linux returns to Windows.',
        '[experimental]',
        'sparseVhd=true'
    )
    [IO.File]::WriteAllLines($wslConfigPath, $new, $utf8NoBom)
    $script:WslConfigChanged = $true
    Add-Done ('%USERPROFILE%\.wslconfig written: memory=' + $memGb + 'GB, swap=' + $swapGb + 'GB, sparseVhd=true (host RAM ' + $ramGb + ' GB)')
} else {
    $ini = Set-IniValues -Lines @(Get-Content -Path $wslConfigPath) -Wanted $wanted -Force $false
    if ($ini.Changed) {
        [IO.File]::WriteAllLines($wslConfigPath, $ini.Lines, $utf8NoBom)
        $script:WslConfigChanged = $true
    }
    foreach ($n in $ini.Notes) {
        $want = ''
        foreach ($w in $wanted) { if ($w.Key -eq $n.Key) { $want = $w.Value } }
        if ($n.State -eq 'added') { Add-Done ('.wslconfig: ' + $n.Key + '=' + $want + ' added') }
        elseif ($n.State -eq 'already') { Add-Already ('.wslconfig: ' + $n.Key + '=' + $n.Current) }
        else { Add-Left ('.wslconfig has ' + $n.Key + '=' + $n.Current + '; the bundle would set ' + $want + '. Left as it is: change it by hand if you want the bundle''s value') }
    }
}

# ---------------------------------------------------------------------------------------------------
Write-Step 4 ('Install ' + $DistroName + ' (without launching it)')
$record = Get-DistroRecord -Name $DistroName
$existedBefore = ($null -ne $record)
if ($existedBefore) {
    Add-Already ($DistroName + ' is registered with WSL')
    if ($record.WslVersion -eq 1) {
        Stop-Script -Message @(
            ($DistroName + ' is a WSL 1 distro. The bundle needs WSL 2.'),
            ('Convert it:  wsl --set-version ' + $DistroName + ' 2    then run this script again.'))
    }
    # v1 (Q26): an existing distro's disk is not made sparse by .wslconfig. Convert it only where WSL takes
    # the change without --allow-unsafe, which this script never passes; otherwise say how to compact by hand.
    $vhdx = ''
    if ($record.BasePath -ne '') { $vhdx = Join-Path $record.BasePath 'ext4.vhdx' }
    $isSparse = $false
    if ($vhdx -ne '' -and (Test-Path $vhdx)) {
        $old = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $flag = (& fsutil.exe sparse queryflag $vhdx 2>&1 | Out-String)
        $ErrorActionPreference = $old
        if ($flag -match 'is set as sparse') { $isSparse = $true }
    }
    $manual = ('To give freed space back to Windows by hand: wsl --shutdown, then compact the distro''s ext4.vhdx ' +
        '(Optimize-VHD -Mode Full, or diskpart: select vdisk file=..., attach vdisk readonly, compact vdisk, detach vdisk)')
    if ($isSparse) {
        Add-Already 'the distro''s disk is sparse'
    } elseif (Test-DistroRunning -Name $DistroName) {
        Add-Left ('the distro''s disk is not sparse and the distro is running, so no conversion was tried. ' + $manual)
    } else {
        $sp = Invoke-Wsl -Arguments @('--manage', $DistroName, '--set-sparse', 'true')
        if ($sp.Code -eq 0) { Add-Done 'the distro''s disk was set sparse (wsl --manage --set-sparse true)' }
        else { Add-Left ('WSL did not make the existing disk sparse without --allow-unsafe, which is never passed. ' + $manual) }
    }
} else {
    $appx = $null
    try { $appx = Get-AppxPackage -Name '*DebianGNULinux*' -ErrorAction SilentlyContinue } catch { $appx = $null }
    if ($null -ne $appx) {
        Add-Already ($DistroName + ' is installed but has not been opened yet')
    } else {
        Write-Host ('  installing ' + $DistroName + ' (wsl --install -d ' + $DistroName + ' --no-launch) ...')
        $inst = Invoke-Wsl -Arguments @('--install', '-d', $DistroName, '--no-launch')
        foreach ($line in $inst.Lines) { Write-Host ('    ' + $line) }
        if ($inst.Code -ne 0) {
            Stop-Script -Code 1 -Message @(
                ('wsl --install -d ' + $DistroName + ' --no-launch failed (exit ' + $inst.Code + ').'),
                'See its output above.')
        }
        Add-Done ($DistroName + ' installed (not launched)')
    }
    $record = Get-DistroRecord -Name $DistroName
}

# ---------------------------------------------------------------------------------------------------
Write-Step 5 'The Linux user account'
# v1 (Q21): Debian creates the user account at its first launch, interactively, so that step is yours.
# The sudoers drop-in below can only be written once the account exists. To confirm on the first run:
# what '--no-launch' leaves behind (a registered distro or not), and how the first launch asks.
$ownerSteps = @(
    'This step is yours:',
    ('  1. Open ' + $DistroName + ' once: Start menu > ' + $DistroName + '  (or:  wsl -d ' + $DistroName + ')'),
    '  2. Create the user account when it asks: a user name and a password.',
    '  3. Type  exit',
    '  4. Run this script again. It goes on from here.')
if ($null -eq $record) {
    Add-Left ('open ' + $DistroName + ' once and create the user account, then rerun this script')
    Stop-Script -Message $ownerSteps
}
$findUser = @'
getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ { print "USER:" $1; exit }'
'@
$r = Invoke-Distro -Script $findUser
$linuxUser = ''
foreach ($line in $r.Lines) { if ($line -match '^USER:([a-z_][a-z0-9_-]*)$') { $linuxUser = $Matches[1] } }
if ($linuxUser -eq '') {
    Add-Left ('open ' + $DistroName + ' once and create the user account, then rerun this script')
    Stop-Script -Message $ownerSteps
}
$r = Invoke-Wsl -Arguments @('-d', $DistroName, '-e', 'id', '-un')
$defaultUser = ''
foreach ($line in $r.Lines) { if ($line -match '^[a-z_][a-z0-9_-]*$') { $defaultUser = $line } }
if ($defaultUser -ne $linuxUser) {
    Add-Left 'make the user account the distro''s default user, then rerun this script'
    Stop-Script -Message @(
        ('The distro has a user account, but it does not start as that user (it starts as "' + $defaultUser + '").'),
        ('Make the account the default:  wsl --manage ' + $DistroName + ' --set-default-user <name>'),
        ('or put  [user]  default=<name>  into /etc/wsl.conf, then:  wsl --terminate ' + $DistroName),
        'Then run this script again.')
}
Add-Already 'the distro has a user account and starts as that user'

# ---------------------------------------------------------------------------------------------------
Write-Step 6 'The distro is Debian 13'
$osRelease = @'
. /etc/os-release
echo "OS:${ID}:${VERSION_ID}"
'@
$r = Invoke-Distro -Script $osRelease
$osId = ''
$osVersion = ''
foreach ($line in $r.Lines) { if ($line -match '^OS:([^:]*):(.*)$') { $osId = $Matches[1]; $osVersion = $Matches[2] } }
if ($osId -ne 'debian' -or $osVersion -ne '13') {
    Stop-Script -Code 1 -Message @(
        ('The distro "' + $DistroName + '" reports ' + $osId + ' ' + $osVersion + ', not Debian 13 (trixie).'),
        'The bundle is written for Debian 13. Nothing inside the distro was changed.')
}
Add-Already 'the distro is Debian 13'

# ---------------------------------------------------------------------------------------------------
Write-Step 7 '/etc/wsl.conf'
# v1 (Q9): systemd on (Docker, kind, Langfuse and Ollama's service need it) and the Windows PATH kept out of
# WSL (a Windows npm or code there would satisfy 'command -v' in setup). [interop] enabled stays at its
# default, true: the bundle's link opener starts a Windows program. Other keys are kept. Setup's preflight
# stops when either of these two is not in effect, so here a differing value is replaced, not just reported.
# Each line of the file comes back behind a marker, so a notice wsl.exe may print on the way is never
# taken for a line of the file, and blank lines survive.
$r = Invoke-Distro -Script 'if [ -f /etc/wsl.conf ]; then sed "s/^/CONF:/" /etc/wsl.conf; fi; echo END:ok'
if (-not ($r.Lines -contains 'END:ok')) {
    Stop-Script -Code 1 -Message @('/etc/wsl.conf could not be read.', ($r.Lines -join ' | '))
}
$confLines = @()
foreach ($line in $r.Lines) { if ($line.StartsWith('CONF:')) { $confLines += $line.Substring(5) } }
$confWanted = @(
    @{ Section = 'boot'; Key = 'systemd'; Value = 'true' },
    @{ Section = 'interop'; Key = 'appendWindowsPath'; Value = 'false' }
)
$conf = Set-IniValues -Lines $confLines -Wanted $confWanted -Force $true
if ($conf.Changed) {
    $text = (($conf.Lines -join "`n") + "`n")
    $confB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($text))
    $writeConf = @'
set -e
f=/etc/wsl.conf
if [ -f "$f" ] && [ ! -f "$f.dev-host-wsl.bak" ]; then cp -p "$f" "$f.dev-host-wsl.bak"; fi
echo @B64@ | base64 -d > "$f.new"
chmod 644 "$f.new"
mv -f "$f.new" "$f"
echo RESULT:written
'@
    $r = Invoke-Distro -Script ($writeConf.Replace('@B64@', $confB64))
    if (-not ($r.Lines -contains 'RESULT:written')) {
        Stop-Script -Code 1 -Message @('/etc/wsl.conf could not be written.', ($r.Lines -join ' | '))
    }
    $script:WslConfChanged = $true
    foreach ($n in $conf.Notes) {
        if ($n.State -eq 'added') { Add-Done ('/etc/wsl.conf: ' + $n.Key + ' set') }
        elseif ($n.State -eq 'changed') { Add-Done ('/etc/wsl.conf: ' + $n.Key + ' changed (was ' + $n.Current + '; the old file is /etc/wsl.conf.dev-host-wsl.bak)') }
        else { Add-Already ('/etc/wsl.conf: ' + $n.Key + '=' + $n.Current) }
    }
} else {
    Add-Already '/etc/wsl.conf: systemd=true and appendWindowsPath=false'
}

# ---------------------------------------------------------------------------------------------------
Write-Step 8 'Bootstrap packages (as root, only when missing)'
# v1 (P11): the drop-in needs visudo, which comes with sudo; cloning the repo needs git and certificates.
# Whether Debian's WSL image has them is to confirm on the first run. The script does not clone the repo.
$bootstrap = @'
missing=""
for p in sudo git ca-certificates; do
    dpkg-query -W -f='${Status}' "$p" 2> /dev/null | grep -q 'ok installed' || missing="$missing $p"
done
if [ -z "$missing" ]; then echo "RESULT:present"; exit 0; fi
export DEBIAN_FRONTEND=noninteractive
apt-get update > /dev/null 2>&1 || { echo "RESULT:update-failed"; exit 1; }
apt-get install -y $missing > /dev/null 2>&1 || { echo "RESULT:install-failed:$missing"; exit 1; }
echo "RESULT:installed:$missing"
'@
$r = Invoke-Distro -Script $bootstrap
$bootResult = ''
foreach ($line in $r.Lines) { if ($line -match '^RESULT:(.*)$') { $bootResult = $Matches[1] } }
if ($bootResult -eq 'present') { Add-Already 'sudo, git and ca-certificates are installed' }
elseif ($bootResult -match '^installed:(.*)$') { Add-Done ('installed in the distro:' + $Matches[1]) }
else {
    Stop-Script -Code 1 -Message @(
        ('Installing the bootstrap packages failed (' + $bootResult + ').'),
        ('Check the network inside the distro (wsl -d ' + $DistroName + ' -u root -- apt-get update), then run this script again.'))
}

# ---------------------------------------------------------------------------------------------------
Write-Step 9 'sudoers drop-in'
# v1 (Q7, Q21, P12): one NOPASSWD line for the user, mode 0440, checked with 'visudo -cf' before it is
# installed and 'visudo -c' after. The account keeps its password. The file name, dev-bundle, has no dot
# on purpose: sudo skips files in /etc/sudoers.d/ whose names contain one.
$dropIn = @'
u='@USER@'
f='@FILE@'
line="$u ALL=(ALL:ALL) NOPASSWD: ALL"
if [ -f "$f" ] && [ "$(cat "$f")" = "$line" ] && [ "$(stat -c '%a %U %G' "$f")" = "440 root root" ] && visudo -c > /dev/null 2>&1; then
    echo "RESULT:present"; exit 0
fi
tmp=$(mktemp)
printf '%s\n' "$line" > "$tmp"
chmod 0440 "$tmp"
if ! visudo -cf "$tmp" > /dev/null 2>&1; then rm -f "$tmp"; echo "RESULT:rejected"; exit 1; fi
install -o root -g root -m 0440 "$tmp" "$f"
rm -f "$tmp"
if ! visudo -c > /dev/null 2>&1; then rm -f "$f"; echo "RESULT:removed"; exit 1; fi
echo "RESULT:written"
'@
$r = Invoke-Distro -Script ($dropIn.Replace('@USER@', $linuxUser).Replace('@FILE@', $DropInPath))
$dropResult = ''
foreach ($line in $r.Lines) { if ($line -match '^RESULT:(.*)$') { $dropResult = $Matches[1] } }
if ($dropResult -eq 'present') { Add-Already ($DropInPath + ' is in place and sudoers parses (visudo -c)') }
elseif ($dropResult -eq 'written') { Add-Done ($DropInPath + ' written for the distro''s user, mode 0440; visudo -c passes') }
elseif ($dropResult -eq 'removed') {
    Stop-Script -Code 1 -Message @(
        'With the drop-in installed, visudo -c failed, so the drop-in was removed again.',
        ('Another file in /etc/sudoers.d is broken: wsl -d ' + $DistroName + ' -u root -- visudo -c'))
} else {
    Stop-Script -Code 1 -Message @(('The sudoers drop-in could not be written (' + $dropResult + ').'), ($r.Lines -join ' | '))
}

# ---------------------------------------------------------------------------------------------------
Write-Step 10 'mkcert on Windows, CAROOT shared into WSL'
# v1 (Q24, P13): DDEV's documented route. 'mkcert -install' on Windows makes one CA that Windows browsers
# trust; CAROOT, shared through WSLENV, makes mkcert inside WSL use the same CA, so setup's 'mkcert -install'
# there trusts it in Linux too. mkcert is used if it is already here (the native dev-setup-windows bundle may
# have installed it), otherwise installed with winget; without winget the step is skipped with a notice and
# setup reports that the CA is not shared. Windows asks once whether to trust the new CA: that click is yours.
$mkcert = $null
$cmd = Get-Command -Name 'mkcert.exe' -ErrorAction SilentlyContinue
if ($null -ne $cmd) { $mkcert = $cmd.Source }
if ($null -eq $mkcert) {
    $winget = Get-Command -Name 'winget.exe' -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        Add-Left 'mkcert: winget is not available, so mkcert was not installed and the CA is not shared. Install mkcert on Windows, then rerun this script'
    } else {
        Write-Host '  installing mkcert with winget ...'
        $old = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $winget.Source install --id FiloSottile.mkcert -e --accept-source-agreements --accept-package-agreements 2>&1 | ForEach-Object { Write-Host ('    ' + "$_") }
        $ErrorActionPreference = $old
        $cmd = Get-Command -Name 'mkcert.exe' -ErrorAction SilentlyContinue
        if ($null -ne $cmd) { $mkcert = $cmd.Source }
        if ($null -eq $mkcert) {
            # winget puts its command links in a folder that is on PATH for new windows only.
            $link = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\mkcert.exe'
            if (Test-Path $link) { $mkcert = $link }
        }
        if ($null -ne $mkcert) { Add-Done 'mkcert installed on Windows (winget)' }
        else { Add-Left 'mkcert: winget did not leave an mkcert.exe this window can find. Open a new PowerShell window and rerun this script' }
    }
} else {
    Add-Already 'mkcert is installed on Windows'
}
if ($null -ne $mkcert) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $mkcert -install 2>&1 | ForEach-Object { Write-Host ('    ' + "$_") }
    $mkcertCode = $LASTEXITCODE
    $caroot = ''
    if ($mkcertCode -eq 0) { $caroot = [string](& $mkcert -CAROOT 2>$null | Select-Object -First 1) }
    $ErrorActionPreference = $old
    if ($mkcertCode -ne 0 -or $caroot.Trim() -eq '' -or -not (Test-Path (Join-Path $caroot.Trim() 'rootCA.pem'))) {
        Add-Left 'mkcert -install did not leave a CA on Windows (was its question declined?). Rerun this script to try again'
    } else {
        $caroot = $caroot.Trim()
        Add-Already 'mkcert''s CA is installed on Windows (mkcert -install)'
        if ([Environment]::GetEnvironmentVariable('CAROOT', 'User') -eq $caroot) {
            Add-Already 'CAROOT is set for your Windows account'
        } else {
            [Environment]::SetEnvironmentVariable('CAROOT', $caroot, 'User')
            Add-Done 'CAROOT set for your Windows account'
        }
        $env:CAROOT = $caroot
        # WSLENV keeps what it already holds. /up: translate the path, and pass it from Windows to WSL only.
        $wslenv = [string][Environment]::GetEnvironmentVariable('WSLENV', 'User')
        $hasCaroot = $false
        foreach ($entry in @($wslenv -split ':')) { if ($entry -match '^CAROOT(/|$)') { $hasCaroot = $true } }
        if ($hasCaroot) {
            Add-Already 'WSLENV shares CAROOT with WSL'
        } else {
            if ($wslenv.Trim() -eq '') { $wslenv = 'CAROOT/up' } else { $wslenv = $wslenv.TrimEnd(':') + ':CAROOT/up' }
            [Environment]::SetEnvironmentVariable('WSLENV', $wslenv, 'User')
            Add-Done 'CAROOT/up added to WSLENV for your Windows account'
        }
    }
}

# ---------------------------------------------------------------------------------------------------
Write-Step 11 'Docker Desktop (check only)'
# v1 (Q4): the bundle installs docker-ce inside the distro, and Docker Desktop's WSL integration for the
# same distro conflicts with it. This step reads Docker Desktop's settings file and reports; it changes
# nothing there. Setup's preflight is the enforcement. The file's name and key names are from memory, in
# both spellings Docker Desktop has used: to confirm on a laptop that has Docker Desktop.
$ddExe = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
$ddSettings = $null
foreach ($name in @('settings-store.json', 'settings.json')) {
    $candidate = Join-Path (Join-Path $env:APPDATA 'Docker') $name
    if ($null -eq $ddSettings -and (Test-Path $candidate)) { $ddSettings = $candidate }
}
if (-not (Test-Path $ddExe) -and $null -eq $ddSettings) {
    Add-Already 'Docker Desktop is not installed (nothing to conflict with docker-ce in the distro)'
} elseif ($null -eq $ddSettings) {
    Add-Left ('Docker Desktop is installed but its settings were not found: check Settings > Resources > WSL integration is off for ' + $DistroName)
} else {
    $json = $null
    try { $json = (Get-Content -Path $ddSettings -Raw | ConvertFrom-Json) } catch { $json = $null }
    $distros = Get-JsonValue -Object $json -Names @('IntegratedWslDistros', 'integratedWslDistros')
    $withDefault = Get-JsonValue -Object $json -Names @('EnableIntegrationWithDefaultWslDistro', 'enableIntegrationWithDefaultWslDistro')
    $integrationOn = $false
    foreach ($d in @($distros)) { if ([string]$d -eq $DistroName) { $integrationOn = $true } }
    if ($withDefault -eq $true -and $null -ne $record -and $record.IsDefault) { $integrationOn = $true }
    if ($null -eq $json) {
        Add-Left ('Docker Desktop''s settings could not be read: check Settings > Resources > WSL integration is off for ' + $DistroName)
    } elseif ($integrationOn) {
        Add-Left ('Docker Desktop''s WSL integration looks ON for ' + $DistroName + '. Turn it off (Settings > Resources > WSL integration, Apply & restart): setup stops while it is on. This script does not change Docker Desktop')
    } else {
        Add-Already ('Docker Desktop is installed; its WSL integration is not on for ' + $DistroName)
    }
}

# ---------------------------------------------------------------------------------------------------
Write-Step 12 'Apply'
# v1 (P14): only this distro is terminated, and only when its wsl.conf changed, so it restarts with systemd.
# A .wslconfig change needs 'wsl --shutdown', which stops every distro, Docker Desktop's included: the
# script never runs it; it prints the command, unless no distro is running.
if ($script:WslConfChanged) {
    $r = Invoke-Wsl -Arguments @('--terminate', $DistroName)
    if ($r.Code -eq 0) { Add-Done ($DistroName + ' terminated, so it restarts with the new /etc/wsl.conf') }
    else { Add-Left ('restart the distro so /etc/wsl.conf takes effect:  wsl --terminate ' + $DistroName) }
}
if ($script:WslConfigChanged) {
    if (Test-AnyDistroRunning) {
        Add-Left '.wslconfig changed and a distro is running: when nothing in WSL is busy, run  wsl --shutdown  so the new memory and swap apply'
    } else {
        Add-Already 'no distro is running, so the new .wslconfig applies the next time WSL starts'
    }
}
if (-not $script:WslConfChanged -and -not $script:WslConfigChanged) { Write-Host '  nothing to apply' }

# ---------------------------------------------------------------------------------------------------
Write-Step 13 'Summary and hand-off'
Show-Summary
Write-Host ''
Write-Host 'Next, in a NEW terminal window (so CAROOT and WSLENV are in its environment):'
Write-Host ('  1. Start Debian:   wsl -d ' + $DistroName)
Write-Host '  2. Clone the repo into the Linux home, never under /mnt:'
Write-Host '       cd ~ && git clone https://github.com/dhouse109/dev-setup-windows-wsl.git'
Write-Host '       cd dev-setup-windows-wsl'
Write-Host '  3. ./dev-init-wsl.sh <flags>     its first run only writes the secrets template'
Write-Host '  4. ./dev-setup-wsl.sh <flags>    then a new terminal, init again, and ./dev-test-wsl.sh <flags>'
Write-Host ''
Write-Host 'dev-host-wsl Version 1 complete.'
exit 0
