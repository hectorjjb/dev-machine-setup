# Windows Setup

## Quick Start

Run from an **elevated** PowerShell prompt (Run as Administrator):

```powershell
powershell -ExecutionPolicy Bypass -File windows\Windows11Setup.ps1
```

When prompted, enter **personal** or **work**. Work devices use Microsoft's
CFS-protected package feed; personal devices use the standard public npm registry.
The choice applies to npm, pnpm, Yarn, Corepack, and the `npmauth` helper.
Azure CLI, Visual Studio Enterprise, WSL, and Ubuntu are installed only for work devices.
Personal setup skips all WSL operations, including updates and Ubuntu cleanup,
and does not uninstall existing apps or Linux distributions.

The script is idempotent — already-installed apps are skipped. Older Ubuntu
cleanup is optional and requires explicit confirmation for each distribution.
Re-running with **personal** also removes the work-specific remote-package allowance
and replaces the work registry defaults. Repository-specific feeds remain supported.

---

## What the Script Does

1. **Installs WinGet** (Windows Package Manager) if missing or outdated, and enables the experimental Microsoft Store source.
2. **Installs apps** via WinGet and the Microsoft Store (see list below).
3. **Removes** unwanted pre-installed apps (3D Print, Mixed Reality Portal,
   Skype, Bing News/Weather, Get Help, Tips, Feedback Hub, Clipchamp,
   Quick Assist).
4. **On work devices only, enables and updates WSL** (Windows Subsystem for Linux)
   and installs Ubuntu 26.04 LTS directly through WSL,
   skipping it if already registered. On later work-device runs, offers to
   delete older version-named Ubuntu distributions, without creating backups.
   Existing distributions are never upgraded.
   If enabling or updating WSL requires a reboot, restart Windows and re-run
   the script to finish setup.
5. **Enables long paths** (registry + `git config --system core.longpaths`).
6. **Configures git** — user name/email and `git lfs install`.
7. **Sets up Node tooling** — installs the latest Node.js LTS release through
   fnm, makes it the default, configures npm, pnpm, Yarn, and Corepack for the
   selected device type, updates npm, and installs yarn and nx globally.
   Work devices also permit npm's `remote` package type because npm 12
   classifies the protected feed's Azure DevOps tarball URLs as remote.
8. **Configures Oh My Posh** — copies the `mt.omp.json` theme, installs the
   CaskaydiaCove Nerd Font, and installs the PowerShell profile from
   `config/Microsoft.PowerShell_profile.ps1`.

---

## What Gets Installed

### Apps (WinGet / Microsoft Store)

- Git, Git LFS, GitHub CLI (`gh`)
- .NET SDK 10 (includes `dotnet` CLI), fnm with Node.js LTS, Python 3.14
- Visual Studio Code, PowerShell 7, Windows Terminal, PowerToys, 7-Zip
- **Work devices only:** Azure CLI, Visual Studio 2026 Enterprise
- Spotify, WhatsApp, Netflix, Plex

### Linux (WSL)

- **Work devices only:** WSL is enabled and updated. Personal setup leaves
  existing WSL installations and distributions untouched.
- **Work devices only:** Ubuntu 26.04 LTS, installed via
  `wsl --install --distribution Ubuntu-26.04 --no-launch`
- On work devices, after Ubuntu 26.04 is already registered, the script offers to remove older
  distributions named `Ubuntu-YY.MM` (for example, `Ubuntu-24.04`).
- **Deletion is permanent and no backup is created.** You must type each
  distribution's exact name to authorize `wsl --unregister`. Press Enter to keep it.
- Newer Ubuntu releases, unversioned `Ubuntu`, custom names, and non-Ubuntu
  distributions are not cleanup targets.

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
  that feed's token is the very thing that's stale. `npmauth`
  fetches the `vsts-npm-auth` tool via the registry selected during setup
  (Microsoft-approved proxy for work, public npm for personal devices),
  while refreshing credentials for whichever feed the nearest
  `.npmrc` (walked up from the current directory, or passed explicitly)
  actually declares — nothing about the target feed is hardcoded. Run it
  from anywhere inside a repo whenever `yarn install`/`npm install` fails
  with a `401` on a private feed.

---

## Manual Steps After Running the Script

- On work devices, **restart Windows** if WSL was enabled or an update requires it, then re-run
  the script to finish setup. Restart or sign out/in for the other
  PATH and long-path changes.
- On work devices, run **`wsl -d Ubuntu-26.04`** after installation to complete first-time Linux
  user setup. The script does not launch Ubuntu interactively.
- On work devices, verify Ubuntu 26.04 works and move any needed files or configuration from the
  old distribution before re-running the script and confirming cleanup. Cleanup
  is not offered during the run that first installs Ubuntu 26.04.
- **Sign in** to the Microsoft Store before running if any Store apps fail to
  install silently.
- On work devices, Visual Studio 2026 **Enterprise** requires a valid license — swap the WinGet
  ID for `Microsoft.VisualStudio.Community` or `.Professional` if needed.
