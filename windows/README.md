# Windows Setup

## Quick Start

Run from an **elevated** PowerShell prompt (Run as Administrator):

```powershell
powershell -ExecutionPolicy Bypass -File windows\Windows11Setup.ps1
```

The script is idempotent — already-installed apps are skipped and re-running is safe.

---

## What the Script Does

1. **Installs WinGet** (Windows Package Manager) if missing or outdated, and enables the experimental Microsoft Store source.
2. **Installs apps** via WinGet and the Microsoft Store (see list below).
3. **Removes** unwanted pre-installed apps (3D Print, Mixed Reality Portal, Skype).
4. **Enables WSL** (Windows Subsystem for Linux) and installs Ubuntu.
5. **Enables long paths** (registry + `git config --system core.longpaths`).
6. **Configures git** — user name/email and `git lfs install`.
7. **Sets up Node tooling** — updates npm, installs yarn and nx globally.
8. **Configures Oh My Posh** — copies the `mt.omp.json` theme, installs the
   CaskaydiaCove Nerd Font, and installs the PowerShell profile from
   `config/Microsoft.PowerShell_profile.ps1`.

---

## What Gets Installed

### Apps (WinGet / Microsoft Store)
- Git, Git LFS, GitHub
- .NET SDK 10, Node.js LTS, Python 3.13, NuGet
- Visual Studio 2026 Enterprise, Visual Studio Code
- Azure CLI, PowerShell 7, Windows Terminal, PowerToys
- Ubuntu 24.04 (WSL), 7-Zip
- Google Chrome, Spotify, WhatsApp, Netflix, Plex, Zoom

### Shell
- **Oh My Posh** prompt with the `mt.omp.json` theme
- **CaskaydiaCove Nerd Font**
- **Terminal-Icons** PowerShell module

---

## Manual Steps After Running the Script

- **Restart** (or sign out/in) so WSL, long-path support, and the PATH changes
  from the new tooling take effect.
- **Sign in** to the Microsoft Store before running if any Store apps fail to
  install silently.
- Visual Studio 2026 **Enterprise** requires a valid license — swap the WinGet
  ID for `Microsoft.VisualStudio.Community` or `.Professional` if needed.
