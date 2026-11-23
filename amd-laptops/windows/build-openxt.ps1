<#
.SYNOPSIS
    Build the OpenXT installer ISO (AMD laptops layer) on Windows with WSL2.

.DESCRIPTION
    Creates a dedicated WSL2 distribution (Ubuntu 20.04 base, the supported
    build host for OpenXT/Yocto dunfell), installs the build dependencies,
    clones this repository into it and runs the build. The ISO is copied to
    your Downloads folder at the end.

    Every step can be run again; finished work is not redone. A failed build
    continues where it stopped when you start the script again.

    Run in a normal (non-admin) PowerShell window:
        powershell -ExecutionPolicy Bypass -File .\build-openxt.ps1

.PARAMETER Step
    all (default), setup, fetch, build or iso.

.PARAMETER Threads
    BitBake/make parallelism. Default: logical CPUs, at most one per 2 GB of
    RAM the WSL VM has.

.PARAMETER Distro
    Name of the WSL distribution to create/use. Default: OpenXT-Build.

.PARAMETER InstallDir
    Where the distribution's virtual disk is stored. Needs about 200 GB free.

.PARAMETER RepoUrl
    Repository with the AMD laptops layer.

.PARAMETER Branch
    Branch of that repository.
#>
[CmdletBinding()]
param(
    [ValidateSet("all", "setup", "fetch", "build", "iso")]
    [string]$Step = "all",
    [int]$Threads = 0,
    [string]$Distro = "OpenXT-Build",
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "OpenXT-Build"),
    [string]$RepoUrl = "https://github.com/hackyannick/OpenXT.git",
    [string]$Branch = "claude/sweet-carson-kvc649"
)

$ErrorActionPreference = "Stop"
# The progress bar slows Invoke-WebRequest down a lot in Windows PowerShell.
$ProgressPreference = "SilentlyContinue"

$BuildUser = "build"
$BaseUrl = "https://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release"
$BaseTarball = "ubuntu-base-20.04.5-base-amd64.tar.gz"
$BaseSha256 = "60e216b60947653dc8989be3821380268315b99b2959c29882781541bfe5a426"
$Workspace = "/home/$BuildUser/openxt-workspace"
$IsoLinuxPath = "$Workspace/build-845g7/deploy/openxt-installer.iso"

function Invoke-Wsl {
    param([string]$User, [string]$Command)
    # --exec: no extra shell between wsl.exe and bash, so the command reaches
    # bash -c unchanged.
    & wsl.exe -d $Distro -u $User --exec bash -c $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command in WSL failed (exit $LASTEXITCODE): $Command"
    }
}

# Run a native command with all output discarded. Windows PowerShell 5.1
# turns redirected stderr of native programs into terminating errors while
# $ErrorActionPreference is "Stop", so relax it for the call.
function Invoke-Quiet {
    param([scriptblock]$Block)
    $saved = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { & $Block *> $null } finally { $ErrorActionPreference = $saved }
}

function Test-DistroExists {
    $list = (& wsl.exe --list --quiet) -replace "`0", "" | ForEach-Object { $_.Trim() }
    return $list -contains $Distro
}

# --- WSL itself ----------------------------------------------------------
Invoke-Quiet { wsl.exe --status }
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL is not installed. Run once in an administrator PowerShell:" -ForegroundColor Yellow
    Write-Host "    wsl --install --no-distribution"
    Write-Host "then reboot and start this script again."
    exit 1
}
Invoke-Quiet { wsl.exe --set-default-version 2 }

# --- Keep Windows awake while this script runs ---------------------------
if (-not ("OpenXT.Power" -as [type])) {
    Add-Type -Namespace OpenXT -Name Power -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint esFlags);
"@
}
# ES_CONTINUOUS | ES_SYSTEM_REQUIRED (0x80000001; hex literals that large are
# negative Int32 in PowerShell, hence decimal)
[void][OpenXT.Power]::SetThreadExecutionState([uint32]2147483649)

try {
    # --- Distribution ----------------------------------------------------
    if (-not (Test-DistroExists)) {
        $drive = Get-PSDrive -Name $InstallDir.Substring(0, 1)
        $freeGb = [math]::Floor($drive.Free / 1GB)
        if ($freeGb -lt 200) {
            Write-Warning "Only $freeGb GB free on $($drive.Name):. The build needs about 200 GB."
        }

        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        $tarball = Join-Path $InstallDir $BaseTarball
        if (-not (Test-Path $tarball)) {
            Write-Host "Downloading $BaseTarball ..."
            Invoke-WebRequest -Uri "$BaseUrl/$BaseTarball" -OutFile $tarball -UseBasicParsing
        }
        $hash = (Get-FileHash -Algorithm SHA256 $tarball).Hash.ToLower()
        if ($hash -ne $BaseSha256) {
            Remove-Item $tarball
            throw "Checksum mismatch for $BaseTarball (got $hash)"
        }

        Write-Host "Creating WSL distribution $Distro in $InstallDir ..."
        & wsl.exe --import $Distro $InstallDir $tarball --version 2
        if ($LASTEXITCODE -ne 0) { throw "wsl --import failed" }
    }

    # --- Repository and build dependencies -------------------------------
    if ($Step -in @("all", "setup")) {
        Write-Host "Installing git and creating user '$BuildUser' ..."
        Invoke-Wsl root "export DEBIAN_FRONTEND=noninteractive && apt-get -o Acquire::Retries=3 update && apt-get -o Acquire::Retries=3 install -y git ca-certificates sudo"
        Invoke-Wsl root "id $BuildUser >/dev/null 2>&1 || useradd -m -s /bin/bash $BuildUser"

        Write-Host "Fetching $RepoUrl ($Branch) ..."
        Invoke-Wsl $BuildUser "mkdir -p $Workspace && cd $Workspace && if [ -d OpenXT/.git ]; then git -C OpenXT pull --ff-only; else git clone -b '$Branch' '$RepoUrl' OpenXT; fi"

        Write-Host "Installing build dependencies (takes a while the first time) ..."
        Invoke-Wsl root "$Workspace/OpenXT/amd-laptops/windows/provision-wsl.sh $BuildUser"

        # Apply /etc/wsl.conf (default user, no Windows PATH).
        Invoke-Quiet { wsl.exe --terminate $Distro }
    }

    # --- Build -----------------------------------------------------------
    # wsl.exe can print notices on stdout; keep the line that is the number.
    $memOut = & wsl.exe -d $Distro -u $BuildUser --exec awk '/^MemTotal:/ { print $2 }' /proc/meminfo
    $memKb = [long](($memOut | Select-String -Pattern '^\d+$' | Select-Object -Last 1).Line)
    $memGb = [math]::Floor($memKb / 1MB)
    Write-Host "WSL VM: $memGb GB RAM, $env:NUMBER_OF_PROCESSORS logical CPUs"
    if ($memGb -lt 12) {
        Write-Warning ("WSL only has $memGb GB. Give it more in $env:USERPROFILE\.wslconfig " +
                       "([wsl2] memory=...) and run 'wsl --shutdown', or the build runs with few threads.")
    }

    $threadEnv = ""
    if ($Threads -gt 0) { $threadEnv = "OPENXT_THREADS=$Threads " }
    Invoke-Wsl $BuildUser "cd $Workspace && ${threadEnv}OpenXT/amd-laptops/windows/build-in-wsl.sh $Step"

    # --- Copy the ISO to Windows -----------------------------------------
    if ($Step -in @("all", "iso")) {
        $isoWin = $null
        foreach ($root in @("\\wsl.localhost\$Distro", "\\wsl$\$Distro")) {
            $candidate = $root + ($IsoLinuxPath -replace "/", "\")
            if (Test-Path $candidate) { $isoWin = $candidate; break }
        }
        if ($null -eq $isoWin) { throw "ISO not found at $IsoLinuxPath" }
        $dest = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads\openxt-installer.iso"
        Copy-Item $isoWin $dest -Force
        Write-Host ""
        Write-Host "Done: $dest" -ForegroundColor Green
        Write-Host "Write it to a USB stick with Rufus in 'DD image' mode (not ISO mode, not Ventoy)."
    }
}
finally {
    # ES_CONTINUOUS (0x80000000): back to normal power management.
    [void][OpenXT.Power]::SetThreadExecutionState([uint32]2147483648)
}
