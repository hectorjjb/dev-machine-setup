#!/bin/bash
set -e

# Detect machine
unameOut="$(uname -s)"
case "${unameOut}" in
  Linux*)     MACHINE=Linux;;
  Darwin*)    MACHINE=Mac;;
  CYGWIN*)    MACHINE=Cygwin;;
  MINGW*)     MACHINE=MinGw;;
  *)          MACHINE="UNKNOWN:${unameOut}"
esac

echo "$MACHINE"

# Installs .oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  # Installs Oh my ZSH with Homebrew (Mac)
  # Note: zsh is the default shell on macOS since Catalina — no need to install it
  if [[ $MACHINE == "Mac" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # Installs Oh my ZSH with Linux
  if [[ $MACHINE == "Linux" ]]; then
    sudo apt install zsh -y
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  fi
fi

# Assumes default ZSH installation
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Installs plugins (skip if already cloned)
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
fi

# Fix permissions
chmod 700 "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

###############################################################################
# Configure ~/.zshrc                                                          #
###############################################################################
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
  echo "\$HOME/.zshrc not found — skipping configuration"
  exit 0
fi

echo "Configuring ~/.zshrc..."

# --- Repair: clean up issues from previous script runs ---

# Remove redundant manual source of zsh-autosuggestions (it's loaded via plugins array)
sed -i '' '/^source.*zsh-autosuggestions\/zsh-autosuggestions\.zsh$/d' "$ZSHRC"

# Remove stale source of empty .bash_profile
if [ -f "$HOME/.bash_profile" ] && [ ! -s "$HOME/.bash_profile" ]; then
  sed -i '' '/^source.*\.bash_profile$/d' "$ZSHRC"
  echo "Removed source of empty .bash_profile"
fi

# Fix broken concatenated PATH lines (e.g. export PATH="...node@20..."export PATH="...node@22...")
# Remove any hardcoded Homebrew node PATH entries — node is managed by brew directly
sed -i '' '/^export PATH="\/opt\/homebrew\/opt\/node@/d' "$ZSHRC"
# Also catch concatenated lines where two exports ended up on one line
sed -i '' '/\/opt\/homebrew\/opt\/node@.*export PATH/d' "$ZSHRC"

# Remove trailing blank lines left by cleanup
sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$ZSHRC"

echo "✓ Repaired stale entries from previous runs"

# --- Set theme to "agnoster" (Oh My Zsh fallback) ---
if grep -q '^ZSH_THEME=' "$ZSHRC"; then
  sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"
  echo "Set theme to agnoster"
else
  # Insert after the ZSH export line
  sed -i '' '/^export ZSH=/a\
ZSH_THEME="agnoster"
' "$ZSHRC"
  echo "Added theme agnoster"
fi

# --- Oh My Posh (overrides ZSH_THEME when available) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OMP_CONFIG_DIR="$HOME/.config/omp"
OMP_THEME="$OMP_CONFIG_DIR/mt.omp.json"

if command -v oh-my-posh &> /dev/null; then
  mkdir -p "$OMP_CONFIG_DIR"
  cp "$SCRIPT_DIR/../config/mt.omp.json" "$OMP_THEME"
  echo "Copied Oh My Posh theme to $OMP_THEME"

  # Add Oh My Posh init to .zshrc (idempotent)
  if ! grep -q 'oh-my-posh init zsh' "$ZSHRC"; then
    echo '' >> "$ZSHRC"
    echo '# Oh My Posh' >> "$ZSHRC"
    echo 'eval "$(oh-my-posh init zsh --config ~/.config/omp/mt.omp.json)"' >> "$ZSHRC"
    echo '' >> "$ZSHRC"
    echo 'clear' >> "$ZSHRC"
    echo "Added Oh My Posh init to ~/.zshrc"
  else
    echo "Oh My Posh init already in ~/.zshrc — skipping"
  fi
else
  echo "oh-my-posh not found — skipping prompt config"
fi

# --- fnm (Fast Node Manager) — adds node/npm/npx to PATH ---
if command -v fnm &> /dev/null; then
  if ! grep -q 'fnm env' "$ZSHRC"; then
    echo '' >> "$ZSHRC"
    echo '# fnm (Node.js version manager)' >> "$ZSHRC"
    echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >> "$ZSHRC"
    echo "Added fnm env to ~/.zshrc"
  else
    echo "fnm env already in ~/.zshrc — skipping"
  fi
else
  echo "fnm not found — skipping Node.js PATH config"
fi

# --- Set plugins: git z zsh-autosuggestions node ---
DESIRED_PLUGINS="plugins=(git z zsh-autosuggestions node)"
if grep -q '^plugins=(' "$ZSHRC"; then
  sed -i '' "s/^plugins=(.*)/$DESIRED_PLUGINS/" "$ZSHRC"
  echo "Updated plugins to: git z zsh-autosuggestions node"
else
  echo "" >> "$ZSHRC"
  echo "$DESIRED_PLUGINS" >> "$ZSHRC"
  echo "Added plugins: git z zsh-autosuggestions node"
fi

# --- Override agnoster blue segments with yellow for contrast ---
AGNOSTER_OVERRIDE='prompt_dir() { prompt_segment yellow black "%~" }'
# Remove any previous override
sed -i '' '/^prompt_dir().*prompt_segment/d' "$ZSHRC"
# Add override after oh-my-zsh is sourced
if ! grep -q 'prompt_dir()' "$ZSHRC"; then
  # Insert after 'source $ZSH/oh-my-zsh.sh'
  sed -i '' "/^source \$ZSH\/oh-my-zsh.sh/a\\
$AGNOSTER_OVERRIDE
" "$ZSHRC"
  echo "Set prompt directory color to yellow"
fi

# --- Source zsh-syntax-highlighting at the end (must be last) ---
SYNTAX_SOURCE="source \"\${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\""
# Remove any old syntax-highlighting source lines (various path formats from previous runs)
sed -i '' '/zsh-syntax-highlighting\.zsh$/d' "$ZSHRC"
# Add it back as the last line
echo "" >> "$ZSHRC"
echo "$SYNTAX_SOURCE" >> "$ZSHRC"
echo "Added zsh-syntax-highlighting source at end of .zshrc"

echo "✓ ~/.zshrc configured"