Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Require elevation — several steps (registry, system-scope git config,
# Remove-AppxPackage -AllUsers, WSL feature) silently fail without it.
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script must be run in an elevated PowerShell (Run as Administrator)."
    exit 1
}

#Install WinGet
#Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'

if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith('msixbundle') } | Select-Object -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
else {
    "winget already installed"
}

# The msstore source has been built-in and stable since winget 1.6,
# so no experimental settings.json is needed anymore.

#Install New apps
Write-Output "Installing Apps"
$apps = @(
    @{name = "Git.Git" },
    @{name = "GitHub.cli" },
    @{name = "GitHub.GitLFS" },
    @{name = "Microsoft.AzureCLI" },
    @{name = "Microsoft.PowerShell" },
    @{name = "Microsoft.WindowsTerminal" },
    @{name = "Microsoft.VisualStudioCode" },
    @{name = "JanDeDobbeleer.OhMyPosh" },
    @{name = "XP89DCGQ3K6VLD"; source = "msstore" },    # Microsoft PowerToys
    @{name = "OpenJS.NodeJS.LTS" },
    @{name = "Microsoft.DotNet.SDK.10" },
    @{name = "Python.Python.3.14" },
    @{name = "Canonical.Ubuntu.2404" },
    @{name = "Docker.DockerDesktop" },
    @{name = "Microsoft.VisualStudio.Enterprise" },    # Visual Studio 2026 Enterprise
    # @{name = "Microsoft.Azure.StorageExplorer" },
    # @{name = "Postman.Postman" },
    # @{name = "Google.Chrome" },
    @{name = "9NCBCSZSJRSB"; source = "msstore" },     # Spotify
    @{name = "9NKSQGP7F2NH"; source = "msstore" },     # WhatsApp
    @{name = "9WZDNCRFJ3TJ"; source = "msstore" },     # Netflix
    @{name = "XP9CDQW6ML4NQN"; source = "msstore" },   # Plex
    @{name = "7zip.7zip" }
    # @{name = "XP99J3KP4XZ4VV"; source = "msstore" }  # Zoom
);

foreach ($app in $apps) {
    try {
        $listApp = winget list --exact -q $app.name --accept-source-agreements 
        if (![String]::Join("", $listApp).Contains($app.name)) {
            Write-Host "Installing: $($app.name)"
            if ($null -ne $app.source) {
                winget install --exact --silent $app.name --source $app.source --accept-package-agreements
            }
            else {
                winget install --exact --silent $app.name --accept-package-agreements
            }
        }
        else {
            Write-Host "Skipping install of $($app.name)"
        }
    }
    catch {
        Write-Output "Error installing $($app.name): $_"
    }
}

#Remove Apps
Write-Output "Removing Apps"

$apps = @(
    "*3DPrint*",
    "Microsoft.MixedReality.Portal",
    "Microsoft.SkypeApp",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsFeedbackHub",
    "Clipchamp.Clipchamp",
    "MicrosoftCorporationII.QuickAssist"
)
foreach ($app in $apps) {
    try {
        Write-Host "Uninstalling $($app)"
        Get-AppxPackage -AllUsers $app | Remove-AppxPackage -AllUsers | Out-Null
    }
    catch {
        Write-Output "Error uninstalling $($app): $_"
    }
}

# Refresh PATH and other env vars (e.g. POSH_THEMES_PATH set by the
# oh-my-posh installer) in the current session so tools just installed
# by winget are usable in the steps below without requiring a new shell.
$env:Path = `
    [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + `
    [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:POSH_THEMES_PATH = `
    [System.Environment]::GetEnvironmentVariable("POSH_THEMES_PATH", "Machine")
if (-not $env:POSH_THEMES_PATH) {
    $env:POSH_THEMES_PATH = `
        [System.Environment]::GetEnvironmentVariable("POSH_THEMES_PATH", "User")
}
if (-not $env:POSH_THEMES_PATH) {
    # Fall back to the default install location used by the winget package.
    $env:POSH_THEMES_PATH = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
}

# Install WSL
# https://learn.microsoft.com/en-us/windows/wsl/install
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -OutVariable WSLStatus | Out-Null
$wslFreshlyInstalled = $false
if ($WSLStatus.State -ne "Enabled") {
    wsl --install
    $wslFreshlyInstalled = $true
}
else {
    Write-Host "WSL already installed. Skipping..."
}

# Enable long paths
try {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
        -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
}
catch {
    Write-Output "Error enabling long paths: $_"
}

# Use Terminal-Icons to add missing folder or file icons,
# and posh-git for git status integration in the prompt.
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
    Install-Module -Name posh-git       -Repository PSGallery -Force
}
catch {
    Write-Output "Error installing PowerShell modules: $_"
}

# Enable git long paths
try {
    git config --system core.longpaths true
}
catch {
    Write-Output "Error enabling git long paths: $_"
}

# Set git user.name
try {
    git config --global user.name "Hector Jimenez"
}
catch {
    Write-Output "Error setting git user.name $_"
}

# Set git user.email
try {
    git config --global user.email hectorjimenez@outlook.com
}
catch {
    Write-Output "Error setting git user.email $_"
}

# Enable git lfs
try {
    git lfs install
}
catch {
    Write-Output "Error enabling git lfs: $_"
}

# Update WSL (skip if WSL was just installed — needs a reboot first)
if ($wslFreshlyInstalled) {
    Write-Host "WSL was just installed — skipping 'wsl --update' until after reboot."
}
else {
    try {
        wsl --update
    }
    catch {
        Write-Output "Error updating WSL: $_"
    }
}

# Update npm
try {
    npm install --global npm
}
catch {
    Write-Output "Error updating npm: $_"
}

# Install yarn
# --allow-scripts permits yarn's preinstall script (no-op on Windows) and
# silences npm 11+ allow-scripts warnings.
try {
    npm install --global yarn --allow-scripts=yarn
}
catch {
    Write-Output "Error installing yarn: $_"
}

# Install nx globally
# --allow-scripts permits nx's postinstall script (soft-fails by design)
# and silences npm 11+ allow-scripts warnings.
try {
    npm install --global nx --allow-scripts=nx
}
catch {
    Write-Output "Error installing nx: $_"
}

###############################################################################
# Oh My Posh configuration                                                    #
###############################################################################

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Copy mt.omp.json theme to Oh My Posh themes directory
try {
    $themeSrc = Join-Path $ScriptDir "config\mt.omp.json"
    if ($env:POSH_THEMES_PATH) {
        if (-not (Test-Path $env:POSH_THEMES_PATH)) {
            # oh-my-posh creates this folder lazily on first run; pre-create it
            # so we can drop the theme in place even on a fresh install.
            New-Item -ItemType Directory -Path $env:POSH_THEMES_PATH -Force | Out-Null
        }
        $themeDst = Join-Path $env:POSH_THEMES_PATH "mt.omp.json"
        Copy-Item -Path $themeSrc -Destination $themeDst -Force
        Write-Host "Copied mt.omp.json to $themeDst"
    }
    else {
        Write-Host "POSH_THEMES_PATH not set — skipping theme copy"
    }
}
catch {
    Write-Output "Error copying Oh My Posh theme: $_"
}

# Install CaskaydiaCove Nerd Font via Oh My Posh
try {
    oh-my-posh font install CascadiaCode
    Write-Host "Installed CaskaydiaCove Nerd Font"
}
catch {
    Write-Output "Error installing Nerd Font: $_"
}

# Configure PowerShell profile for Oh My Posh
try {
    $profileSrc = Join-Path $ScriptDir "config\Microsoft.PowerShell_profile.ps1"
    $profileDir = Split-Path -Parent $PROFILE.CurrentUserAllHosts
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    Copy-Item -Path $profileSrc -Destination $PROFILE.CurrentUserAllHosts -Force
    Write-Host "Configured PowerShell profile at $($PROFILE.CurrentUserAllHosts)"
}
catch {
    Write-Output "Error configuring PowerShell profile: $_"
}
