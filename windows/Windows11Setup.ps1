Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Require elevation - several steps (registry, system-scope git config,
# Remove-AppxPackage -AllUsers, WSL feature) silently fail without it.
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script must be run in an elevated PowerShell (Run as Administrator)."
    exit 1
}

do {
    $deviceType = (Read-Host "Is this a personal or work device? Enter personal or work").Trim().ToLowerInvariant()
    if ($deviceType -notin @("personal", "work")) {
        Write-Warning "Please enter personal or work."
    }
} until ($deviceType -in @("personal", "work"))
$isWorkDevice = $deviceType -eq "work"

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
    @{name = "Microsoft.PowerShell" },
    @{name = "Microsoft.WindowsTerminal" },
    @{name = "Microsoft.VisualStudioCode" },
    @{name = "JanDeDobbeleer.OhMyPosh" },
    @{name = "XP89DCGQ3K6VLD"; source = "msstore" },    # Microsoft PowerToys
    @{name = "Schniz.fnm" },
    @{name = "Microsoft.DotNet.SDK.10" },
    @{name = "Python.Python.3.14" },
    # @{name = "Microsoft.Azure.StorageExplorer" },
    # @{name = "Postman.Postman" },
    # @{name = "Google.Chrome" },
    @{name = "9NCBCSZSJRSB"; source = "msstore" },     # Spotify
    @{name = "9NKSQGP7F2NH"; source = "msstore" },     # WhatsApp
    # @{name = "9WZDNCRFJ3TJ"; source = "msstore" },     # Netflix
    @{name = "XP9CDQW6ML4NQN"; source = "msstore" },   # Plex
    @{name = "7zip.7zip" }
    # @{name = "XP99J3KP4XZ4VV"; source = "msstore" }  # Zoom
);

if ($isWorkDevice) {
    $apps += @(
        @{name = "Microsoft.AzureCLI" },
        @{name = "Microsoft.VisualStudio.Enterprise" }    # Visual Studio 2026 Enterprise
    )
}

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

# Install the latest Node.js LTS release through fnm and make it the default.
try {
    if (-not (Get-Command fnm -ErrorAction SilentlyContinue)) {
        throw "fnm is unavailable after installation"
    }

    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
    fnm install --lts
    if ($LASTEXITCODE -ne 0) {
        throw "fnm install exited with code $LASTEXITCODE"
    }
    fnm default lts-latest
    if ($LASTEXITCODE -ne 0) {
        throw "fnm default exited with code $LASTEXITCODE"
    }
    fnm use default
    if ($LASTEXITCODE -ne 0) {
        throw "fnm use exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Output "Error configuring Node.js with fnm: $_"
}

# Install WSL and Ubuntu, with optional cleanup, only on work devices.
# https://learn.microsoft.com/en-us/windows/wsl/install
if ($isWorkDevice) {
    try {
        if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
            throw "wsl.exe is unavailable; restart Windows and run this script again."
        }

        $wslReady = $false
        wsl.exe --status 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            wsl.exe --install --no-distribution
            if ($LASTEXITCODE -notin @(0, 3010)) {
                throw "WSL installation exited with code $LASTEXITCODE"
            }
            Write-Warning "Restart Windows and run this script again to finish WSL setup."
        }
        else {
            # Ubuntu's tar-based distribution format requires a recent WSL release.
            wsl.exe --update
            if ($LASTEXITCODE -eq 3010) {
                Write-Warning "WSL was updated; restart Windows and run this script again to finish WSL setup."
            }
            elseif ($LASTEXITCODE -ne 0) {
                throw "WSL update exited with code $LASTEXITCODE"
            }
            else {
                $wslReady = $true
            }
        }

        if ($wslReady) {
            $installedDistros = @(wsl.exe --list --quiet)
            if ($LASTEXITCODE -ne 0) {
                throw "Listing WSL distributions exited with code $LASTEXITCODE"
            }
            # Windows PowerShell can retain NUL characters in WSL's UTF-16 output.
            $installedDistros = $installedDistros | ForEach-Object { $_.Replace("`0", "").Trim() }
            if ($installedDistros -contains "Ubuntu-26.04") {
                Write-Host "Ubuntu 26.04 LTS already installed. Skipping..."
                $olderUbuntuDistros = $installedDistros | Where-Object {
                    $_ -match '^Ubuntu-(\d{2}\.\d{2})$' -and
                    [version]($Matches[1]) -lt [version]"26.04"
                }
                foreach ($distro in $olderUbuntuDistros) {
                    Write-Warning "Removing '$distro' permanently deletes all its Linux files, packages, and settings. No backup will be created."
                    $confirmation = Read-Host "Only proceed if Ubuntu 26.04 is ready and you no longer need this data. Type '$distro' to delete it, or press Enter to keep it"
                    if ($confirmation -ceq $distro) {
                        wsl.exe --unregister $distro
                        if ($LASTEXITCODE -ne 0) {
                            throw "Removing '$distro' exited with code $LASTEXITCODE"
                        }
                        Write-Host "Removed '$distro'."
                    }
                    else {
                        Write-Host "Keeping '$distro'."
                    }
                }
            }
            else {
                wsl.exe --install --distribution Ubuntu-26.04 --no-launch
                if ($LASTEXITCODE -eq 3010) {
                    Write-Warning "Restart Windows to finish installing Ubuntu 26.04 LTS."
                }
                elseif ($LASTEXITCODE -ne 0) {
                    throw "Ubuntu 26.04 LTS installation exited with code $LASTEXITCODE"
                }
                else {
                    Write-Host "Ubuntu 26.04 LTS installed. Run 'wsl -d Ubuntu-26.04' to complete first-time user setup."
                    Write-Host "After verifying Ubuntu 26.04 and moving any needed files, re-run this script for optional cleanup of older Ubuntu releases."
                }
            }
        }
    }
    catch {
        Write-Output "Error configuring WSL and Ubuntu: $_"
    }
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

# Keep registry defaults at user level so repositories can select private feeds.
$npmRegistry = if ($isWorkDevice) {
    "https://packagefeedproxy.microsoft.io/npm/"
}
else {
    "https://registry.npmjs.org/"
}
[string[]]$npmRemoteArgs = if ($isWorkDevice) { @("--allow-remote=all") } else { @() }

try {
    npm config set registry $npmRegistry --location=user
    if ($LASTEXITCODE -ne 0) {
        throw "npm config exited with code $LASTEXITCODE"
    }
    if ($isWorkDevice) {
        # npm 12 treats the proxy's Azure DevOps tarball URLs as remote packages.
        npm config set allow-remote all --location=user
    }
    else {
        npm config delete allow-remote --location=user
    }
    if ($LASTEXITCODE -ne 0) {
        throw "npm config exited with code $LASTEXITCODE"
    }

    if ($isWorkDevice) {
        $env:NPM_CONFIG_ALLOW_REMOTE = "all"
        [Environment]::SetEnvironmentVariable("NPM_CONFIG_ALLOW_REMOTE", "all", "User")
    }
    else {
        Remove-Item Env:NPM_CONFIG_ALLOW_REMOTE -ErrorAction SilentlyContinue
        [Environment]::SetEnvironmentVariable("NPM_CONFIG_ALLOW_REMOTE", $null, "User")
    }
    $env:COREPACK_NPM_REGISTRY = $npmRegistry
    [Environment]::SetEnvironmentVariable("COREPACK_NPM_REGISTRY", $npmRegistry, "User")

    # Environment-level registry settings override project .npmrc/.yarnrc files.
    # Remove values written by older versions of this script so repositories can
    # use private feeds while the user-level defaults above still cover public npm.
    Remove-Item Env:NPM_CONFIG_REGISTRY -ErrorAction SilentlyContinue
    Remove-Item Env:YARN_NPM_REGISTRY_SERVER -ErrorAction SilentlyContinue
    [Environment]::SetEnvironmentVariable("NPM_CONFIG_REGISTRY", $null, "User")
    [Environment]::SetEnvironmentVariable("YARN_NPM_REGISTRY_SERVER", $null, "User")
}
catch {
    Write-Output "Error configuring the $deviceType npm registry: $_"
}

# Update npm
try {
    npm install --global npm @npmRemoteArgs --registry=$npmRegistry
    if ($LASTEXITCODE -ne 0) {
        throw "npm exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Output "Error updating npm: $_"
}

# Install yarn
# --allow-scripts permits yarn's preinstall script (no-op on Windows) and
# silences npm 11+ allow-scripts warnings.
try {
    npm install --global yarn @npmRemoteArgs --allow-scripts=yarn --registry=$npmRegistry
    if ($LASTEXITCODE -ne 0) {
        throw "npm exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Output "Error installing yarn: $_"
}

# Remove the Yarn Classic registry override written by older versions of this
# script. Yarn reads the user-level npm registry above, while repository
# .npmrc files can override it for authenticated private feeds.
try {
    yarn config delete registry
    if ($LASTEXITCODE -ne 0) {
        throw "yarn exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Output "Error removing the legacy Yarn registry override: $_"
}

# Install nx globally
# --allow-scripts permits nx's postinstall script (soft-fails by design)
# and silences npm 11+ allow-scripts warnings.
try {
    npm install --global nx @npmRemoteArgs --allow-scripts=nx --registry=$npmRegistry
    if ($LASTEXITCODE -ne 0) {
        throw "npm exited with code $LASTEXITCODE"
    }
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
        Write-Host "POSH_THEMES_PATH not set - skipping theme copy"
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
    $profileDir = Split-Path -Parent $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    Copy-Item -Path $profileSrc -Destination $PROFILE.CurrentUserCurrentHost -Force
    Write-Host "Configured PowerShell profile at $($PROFILE.CurrentUserCurrentHost)"
}
catch {
    Write-Output "Error configuring PowerShell profile: $_"
}
