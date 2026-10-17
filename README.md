# dev-machice-setup

Personal scripts to configure new development machines (macOS & Windows). Automates system preferences, package installation, and shell setup so a fresh machine is ready to code in minutes.

## What it does

### macOS
- **System preferences** — Finder, Dock, keyboard, screenshots, Safari, and more
- **Homebrew packages** — CLI tools (git, gh, ripgrep, fzf, jq, etc.) and apps (VS Code, Edge, Teams, Spotify, etc.)
- **Zsh configuration** — Oh My Zsh with plugins (autosuggestions, syntax highlighting) and the `apple` theme

### Windows
- **WinGet packages** — Dev tools and apps via Windows Package Manager

## Usage

### macOS
```bash
bash mac/setup-new-mac.sh
```

### Windows

Open **PowerShell as Administrator**, navigate to the repository root, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\windows\Windows11Setup.ps1"
```

The execution-policy bypass applies only to the new PowerShell process. Setup
also persists `RemoteSigned` for the current user unless an organizational policy
is configured, allowing the profile to load after restarting Windows. Run setup
as the Windows account that will use the profile. Running as Administrator alone
does not allow scripts, and the policy command inside the script cannot unblock
it because PowerShell checks the policy before executing its first line.

See [Windows setup instructions](windows/README.md#execution-policy-troubleshooting)
for an alternative command sequence and managed-device troubleshooting.
