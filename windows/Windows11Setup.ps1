Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

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

#Configure WinGet
Write-Output "Configuring winget"

#winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
$settingsJson = 
@"
    {
        // For documentation on these settings, see: https://aka.ms/winget-settings
        "experimentalFeatures": {
          "experimentalMSStore": true,
        }
    }
"@;
$settingsJson | Out-File $settingsPath -Encoding utf8

#Install New apps
Write-Output "Installing Apps"
$apps = @(
    @{name = "Git.Git" },
    @{name = "Microsoft.NuGet" },
    @{name = "Microsoft.AzureCLI" }, 
    @{name = "Microsoft.PowerShell" }, 
    @{name = "Microsoft.VisualStudioCode" }, 
    @{name = "9N0DX20HK701"; source = "msstore" },      # Microsoft Windows Terminal
    # @{name = "Microsoft.Azure.StorageExplorer" }, 
    @{name = "XP89DCGQ3K6VLD"; source = "msstore" },    # Microsoft PowerToys
    @{name = "GitHub.GitLFS" },
    @{name = "OpenJS.NodeJS.LTS" },
    @{name = "Microsoft.DotNet.SDK.10" },
    @{name = "Canonical.Ubuntu.2404" },
    @{name = "XP8K0HKJFRXGCK"; source = "msstore" },    # oh-my-posh
    # @{name = "Postman.Postman" },
    @{name = "Python.Python.3.13" },
    @{name = "Google.Chrome" },
    @{name = "Microsoft.VisualStudio.Enterprise" },    # Visual Studio 2026 Enterprise
    @{name = "9NCBCSZSJRSB"; source = "msstore" },      # Spotify
    @{name = "9NKSQGP7F2NH"; source = "msstore" }       # WhatsApp
    @{name = "9WZDNCRFJ3TJ"; source = "msstore" }       # Netflix
    @{name = "XP9CDQW6ML4NQN"; source = "msstore" }     # Plex
    @{name = "7zip.7zip" },
    @{name = "XP99J3KP4XZ4VV"; source = "msstore" }     # Zoom
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

$apps = "*3DPrint*", "Microsoft.MixedReality.Portal", "Microsoft.SkypeApp"
foreach ($app in $apps) {
    try {
        Write-Host "Uninstalling $($app)"
        Get-AppxPackage -AllUsers $app | Remove-AppxPackage | Out-Null
    }
    catch {
        Write-Output "Error uninstalling $($app): $_"
    }
}

# Install WSL
# https://learn.microsoft.com/en-us/windows/wsl/install
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -OutVariable WSLStatus | Out-Null
if ($WSLStatus.State -ne "Enabled") {
    wsl --install
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

# Use Terminal-Icons to add missing folder or file icons
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
}
catch {
    Write-Output "Error enabling git long paths: $_"
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

# Update WSL
try {
    wsl --update
}
catch {
    Write-Output "Error updating WSL: $_"
}

# Update npm
try {
    npm install --global npm
}
catch {
    Write-Output "Error updating npm: $_"
}

# Install yarn
try {
    npm install --global yarn
}
catch {
    Write-Output "Error installing yarn: $_"
}

# Install nx globally
try {
    npm install --global nx
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
    $themeDst = Join-Path $env:POSH_THEMES_PATH "mt.omp.json"
    if ($env:POSH_THEMES_PATH -and (Test-Path $env:POSH_THEMES_PATH)) {
        Copy-Item -Path $themeSrc -Destination $themeDst -Force
        Write-Host "Copied mt.omp.json to $themeDst"
    }
    else {
        Write-Host "POSH_THEMES_PATH not set or not found — skipping theme copy"
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
