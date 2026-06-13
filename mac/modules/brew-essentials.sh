#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install Homebrew (if not installed)
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Add Homebrew to PATH for this session (and persist in .zprofile)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo >> "$HOME/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$HOME/.zprofile"
  fi
fi
# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install everything declared in the Brewfile (formulae, casks, fonts, taps).
# Idempotent — `brew bundle` skips anything already installed.
brew bundle --file "$SCRIPT_DIR/../Brewfile"

# Node.js (latest LTS version via fnm — fnm itself comes from the Brewfile)
if command -v fnm &> /dev/null; then
  eval "$(fnm env)"
  fnm install --lts
  fnm default lts-latest
fi

# Install global npm packages
npm install --global npm || true
npm install --global nx || true

# Remove outdated versions from the cellar.
brew cleanup

# Git configuration (parity with the Windows setup)
if command -v git &> /dev/null; then
  git config --global user.name "Hector Jimenez"
  git config --global user.email hectorjimenez@outlook.com
  echo "Configured global git user.name / user.email"
fi
if command -v git-lfs &> /dev/null || command -v git &> /dev/null; then
  git lfs install || true
fi