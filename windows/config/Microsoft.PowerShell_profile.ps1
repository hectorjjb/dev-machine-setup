Import-Module -Name Terminal-Icons

$themePath = if ($env:POSH_THEMES_PATH) {
    Join-Path $env:POSH_THEMES_PATH "mt.omp.json"
}
else {
    Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes\mt.omp.json"
}

if (Test-Path $themePath) {
    oh-my-posh init pwsh --config $themePath | Invoke-Expression
}
else {
    Write-Warning "Oh My Posh theme not found at '$themePath'."
}

Clear-Host #To start with a clean Shell

# fnm - Fast Node Manager (auto-switch Node versions per project)
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# Refreshes ADO package-feed credentials (vsts-npm-auth) for the current repo.
#
# Microsoft-managed devices block direct TLS access to the public npm
# registry, so `npx vsts-npm-auth` can fail even when the repo's own
# .npmrc/yarn install works fine: npx inherits whatever registry the
# project's .npmrc sets (often a private, authenticated ADO feed) to
# resolve vsts-npm-auth itself, creating a catch-22 when that feed's
# token is the very thing that's stale.
#
# Fix: always fetch the vsts-npm-auth tool via the Microsoft-approved
# public npm proxy (the one known to be reachable from this device),
# while passing -config to the nearest .npmrc so credentials are
# refreshed for whatever private feed that project actually declares.
# Nothing about the target feed/registry is hardcoded here.
function Update-NpmAuth {
    param(
        [string]$NpmrcPath
    )

    if (-not $NpmrcPath) {
        $dir = Get-Location
        while ($dir -and -not (Test-Path (Join-Path $dir ".npmrc"))) {
            $parent = Split-Path $dir -Parent
            if ($parent -eq $dir) { $dir = $null; break }
            $dir = $parent
        }
        if (-not $dir) {
            Write-Error "No .npmrc found in the current directory or any parent directory."
            return
        }
        $NpmrcPath = Join-Path $dir ".npmrc"
    }

    if (-not (Test-Path $NpmrcPath)) {
        Write-Error ".npmrc not found at '$NpmrcPath'."
        return
    }

    $proxyRegistry = $env:COREPACK_NPM_REGISTRY
    if (-not $proxyRegistry) {
        $proxyRegistry = "https://packagefeedproxy.microsoft.io/npm/"
    }

    npx --registry=$proxyRegistry vsts-npm-auth -config $NpmrcPath -F
}
Set-Alias npmauth Update-NpmAuth
