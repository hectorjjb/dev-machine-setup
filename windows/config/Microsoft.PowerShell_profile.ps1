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
