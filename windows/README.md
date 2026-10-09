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
3. **Removes** unwanted pre-installed apps (3D Print, Mixed Reality Portal,
   Skype, Bing News/Weather, Get Help, Tips, Feedback Hub, Clipchamp,
   Quick Assist).
4. **Enables WSL** (Windows Subsystem for Linux) and installs Ubuntu.
5. **Enables long paths** (registry + `git config --system core.longpaths`).
6. **Configures git** — user name/email and `git lfs install`.
7. **Sets up Node tooling** — installs the latest Node.js LTS release through
   fnm, makes it the default, routes npm, pnpm, Yarn, and Corepack through
   Microsoft's CFS-protected package feed, updates npm, and installs yarn and
   nx globally. It also permits npm's `remote` package type because npm 12
   classifies the protected feed's Azure DevOps tarball URLs as remote.
8. **Configures Oh My Posh** — copies the `mt.omp.json` theme, installs the
   CaskaydiaCove Nerd Font, and installs the PowerShell profile from
   `config/Microsoft.PowerShell_profile.ps1`.

---

## What Gets Installed

### Apps (WinGet / Microsoft Store)

- Git, Git LFS, GitHub CLI (`gh`)
- .NET SDK 10 (includes `dotnet` CLI), fnm with Node.js LTS, Python 3.14
- Visual Studio 2026 Enterprise, Visual Studio Code
- Azure CLI, PowerShell 7, Windows Terminal, PowerToys
- Ubuntu 24.04 (WSL), 7-Zip
- Spotify, WhatsApp, Netflix, Plex

### Shell

- **Oh My Posh** prompt (winget source) with the `mt.omp.json` theme
- **CaskaydiaCove Nerd Font**
- **Terminal-Icons** and **posh-git** PowerShell modules
- **fnm** with automatic Node version switching when a project declares one
- **`npmauth`** (`Update-NpmAuth`) — refreshes ADO package-feed credentials
  (`vsts-npm-auth`) for the current repo. Microsoft-managed devices block
  direct access to the public npm registry, so plain `npx vsts-npm-auth`
  can fail even when the repo's own `.npmrc`-driven installs work: npx
  inherits the project's `.npmrc` registry (often a private, authenticated
  ADO feed) to resolve `vsts-npm-auth` itself, which is a catch-22 when
  that feed's token is the very thing that's stale. `npmauth` always
  fetches the `vsts-npm-auth` tool via the Microsoft-approved public npm
  proxy, while refreshing credentials for whichever feed the nearest
  `.npmrc` (walked up from the current directory, or passed explicitly)
  actually declares — nothing about the target feed is hardcoded. Run it
  from anywhere inside a repo whenever `yarn install`/`npm install` fails
  with a `401` on a private feed.

---

## Manual Steps After Running the Script

- **Restart** (or sign out/in) so WSL, long-path support, and the PATH changes
  from the new tooling take effect.
- **Sign in** to the Microsoft Store before running if any Store apps fail to
  install silently.
- Visual Studio 2026 **Enterprise** requires a valid license — swap the WinGet
  ID for `Microsoft.VisualStudio.Community` or `.Professional` if needed.
