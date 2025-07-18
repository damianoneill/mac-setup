#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------
# Check and install Homebrew (Apple Silicon only)
# ----------------------------------------
if ! command -v brew &>/dev/null; then
  echo ">>> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo ">>> Fixing permissions for Homebrew directories to avoid zsh compinit warnings..."
chmod g-w /opt/homebrew/share || true


# ----------------------------------------
# Install updated Bash and Zsh, set Zsh as default
# ----------------------------------------
brew install bash zsh || true

# Add Homebrew zsh to allowed shells if not already there
BREW_ZSH="$(brew --prefix)/bin/zsh"
if ! grep -Fxq "$BREW_ZSH" /etc/shells; then
  echo ">>> Adding Homebrew zsh to /etc/shells..."
  echo "$BREW_ZSH" | sudo tee -a /etc/shells
fi

# Add Homebrew bash to allowed shells if not already there
BREW_BASH="$(brew --prefix)/bin/bash"
if ! grep -Fxq "$BREW_BASH" /etc/shells; then
  echo ">>> Adding Homebrew bash to /etc/shells..."
  echo "$BREW_BASH" | sudo tee -a /etc/shells
fi

# Set zsh as default shell if it isn't already
if [[ "$SHELL" != "$BREW_ZSH" ]]; then
  echo ">>> Setting default shell to Homebrew zsh..."
  chsh -s "$BREW_ZSH"
  echo "✅ Shell changed to $BREW_ZSH"
else
  echo "✅ Default shell is already Homebrew zsh."
fi

# ----------------------------------------
# Install Zsh tools & improvements
# ----------------------------------------
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship zoxide || true

ZSHRC="$HOME/.zshrc"

add_to_zshrc() {
  local line="$1"
  grep -qxF "$line" "$ZSHRC" || echo "$line" >> "$ZSHRC"
}

add_to_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"'
add_to_zshrc 'eval "$(starship init zsh)"'
add_to_zshrc 'eval "$(zoxide init zsh)"'
add_to_zshrc 'source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
add_to_zshrc 'source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
add_to_zshrc 'fpath+=("$(brew --prefix)/share/zsh-completions")'
add_to_zshrc 'autoload -Uz compinit && compinit'

# -------------------------------------
# Homebrew apps to install
# -------------------------------------
declare -a terminal=(iterm2 tmux neovim)
declare -a toolsAlternative=(lsd bat fd rg htop)
declare -a productivity=(
  topgrade asdf cloc chromedriver universal-ctags ctop curl dos2unix
  docker-compose git git-extras git-lfs nmap pass shellcheck telnet
  the_silver_searcher tree wget xquartz jq python-yq
  docker-credential-helper fzf z dive tig lazygit gh
)
declare -a kubernetes=(k3d k9s)
declare -a guiApps=(
  firefox google-chrome brave-browser slack
  spotify teamviewer visual-studio-code whatsapp
  docker ollama
)
declare -a testTools=(
  pre-commit vale hadolint
)

# Fix: combine all arrays properly for one brew install command
echo ">>> Installing Homebrew packages..."
brew install --no-quarantine "${terminal[@]}" \
  "${toolsAlternative[@]}" \
  "${productivity[@]}" \
  "${kubernetes[@]}" \
  "${testTools[@]}" || true

echo ">>> Installing GUI applications..."
brew install --cask --no-quarantine "${guiApps[@]}" || true

# -------------------------------------
# Add runtime tool support to zshrc
# -------------------------------------
add_to_zshrc 'source "$(brew --prefix asdf)/libexec/asdf.sh"'
add_to_zshrc '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
add_to_zshrc 'eval "$(direnv hook zsh)"'

# -------------------------------------
# Init tools for current session
# -------------------------------------
source "$(brew --prefix asdf)/libexec/asdf.sh"
"$(brew --prefix)/opt/fzf/install" --all

# -------------------------------------
# Helper: install asdf plugin+version
# -------------------------------------
install_asdf_plugin() {
  local plugin="$1"
  local repo="$2"
  local version="${3:-latest}"

  # Check if plugin is already installed
  if ! asdf plugin list | grep -qx "$plugin"; then
    echo ">>> Installing asdf plugin: $plugin"
    if [[ -n "$repo" ]]; then
      asdf plugin add "$plugin" "$repo"
    else
      asdf plugin add "$plugin"
    fi
  else
    echo "✅ asdf plugin $plugin already installed"
  fi

  # Install the version if not already installed
  if [[ "$version" == "latest" ]]; then
    # Try to get the actual latest version
    echo ">>> Finding latest version for $plugin..."
    actual_version=$(asdf latest "$plugin" 2>/dev/null || echo "")
    if [[ -n "$actual_version" ]]; then
      version="$actual_version"
      echo ">>> Latest version for $plugin is: $version"
    else
      echo "⚠️ Could not determine latest version for $plugin, trying generic 'latest'"
    fi
  fi

  if ! asdf list "$plugin" 2>/dev/null | grep -qx "$version"; then
    echo ">>> Installing $plugin $version"
    if ! asdf install "$plugin" "$version"; then
      echo "⚠️ Failed to install $plugin $version, skipping"
      return 1
    fi
  else
    echo "✅ $plugin $version already installed"
  fi

  # Set global version using the working method
  echo ">>> Setting global version for $plugin to $version"
  cd "$HOME" && asdf set "$plugin" "$version" || echo "⚠️ Could not set global version for $plugin"
}

# -------------------------------------
# Install asdf toolchains (with specific versions for problematic ones)
# -------------------------------------
echo ">>> Installing development languages via asdf..."
install_asdf_plugin golang https://github.com/kennyp/asdf-golang.git
install_asdf_plugin nodejs https://github.com/asdf-vm/asdf-nodejs.git
install_asdf_plugin python https://github.com/danhper/asdf-python.git

# Java requires specific version handling
echo ">>> Installing Java..."
if ! asdf plugin list | grep -qx "java"; then
  echo ">>> Installing asdf plugin: java"
  asdf plugin add java https://github.com/halcyon/asdf-java.git
else
  echo "✅ asdf plugin java already installed"
fi

# Get the latest LTS Java version
LATEST_JAVA=$(asdf list all java | grep -E "openjdk-[0-9]+$" | tail -1 | tr -d ' ')
if [[ -n "$LATEST_JAVA" ]]; then
  echo ">>> Installing Java $LATEST_JAVA"
  if ! asdf list java 2>/dev/null | grep -qx "$LATEST_JAVA"; then
    asdf install java "$LATEST_JAVA"
  fi
  asdf set java "$LATEST_JAVA" || echo "⚠️ Could not set global Java version"
else
  echo "⚠️ Could not determine latest Java version, skipping"
fi

install_asdf_plugin trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git
install_asdf_plugin kubectl https://github.com/Banno/asdf-kubectl.git
install_asdf_plugin helm https://github.com/Antiarchitect/asdf-helm.git
install_asdf_plugin krew https://github.com/nlamirault/asdf-krew.git v0.4.5

# -------------------------------------
# Install modern Python package managers
# -------------------------------------
echo ">>> Installing UV Python package manager (recommended)..."
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  add_to_zshrc 'export PATH="$HOME/.cargo/bin:$PATH"'
  echo "✅ UV installed successfully"
else
  echo "✅ UV already installed"
fi

echo ">>> Installing Rye Python package manager (legacy support)..."
if ! command -v rye &>/dev/null; then
  curl -sSf https://rye.astral.sh/get | bash
  add_to_zshrc 'source "$HOME/.rye/env"'
  echo "✅ Rye installed successfully"
else
  echo "✅ Rye already installed"
fi

# -------------------------------------
# Install Ruff linter and formatter
# -------------------------------------
echo ">>> Installing Ruff Python linter and formatter..."
if command -v uv &>/dev/null; then
  # Install with uv tool (recommended by Ruff)
  uv tool install ruff@latest
  echo "✅ Ruff installed successfully with uv tool"
elif command -v curl &>/dev/null; then
  # Install with the standalone installer
  curl -LsSf https://astral.sh/ruff/install.sh | sh
  echo "✅ Ruff installed successfully with standalone installer"
elif command -v brew &>/dev/null; then
  # Fallback to Homebrew
  brew install ruff
  echo "✅ Ruff installed successfully with Homebrew"
else
  echo "⚠️ Could not install Ruff - no compatible installation method found"
fi

# -----------------------------------
# Enable kubectl krew plugin support
# -----------------------------------
export PATH="${HOME}/.krew/bin:$PATH"
add_to_zshrc 'export PATH="$HOME/.krew/bin:$PATH"'
kubectl krew install tail || echo "krew tail already installed"

# -----------------------------------
# Setup direnv and quiet output
# -----------------------------------
echo ">>> Setting up direnv..."
install_asdf_plugin direnv "" latest

# Configure direnv properly
mkdir -p ~/.config/direnv
touch ~/.config/direnv/direnvrc
grep -qxF 'export DIRENV_LOG_FORMAT=""' ~/.config/direnv/direnvrc ||
  echo 'export DIRENV_LOG_FORMAT=""' >>~/.config/direnv/direnvrc

# Create .envrc file but don't use problematic asdf integration
if [ -f ~/.envrc ]; then
  # Remove problematic 'use asdf' line if it exists
  grep -v "use asdf" ~/.envrc > ~/.envrc.tmp && mv ~/.envrc.tmp ~/.envrc || rm -f ~/.envrc.tmp
fi

# Setup direnv with shell integration (skip the problematic asdf setup for now)
if command -v direnv &>/dev/null; then
  echo "✅ direnv installed successfully"
else
  echo "⚠️ direnv setup may need manual configuration"
fi

# --------------------------------------------
# Upgrade npm and install global tools
# --------------------------------------------
echo ">>> Installing npm global packages..."
if command -v npm &>/dev/null; then
  npm install -g npm@latest meta git-open typescript eslint prettier yarn || true
else
  echo "⚠️ npm not available yet, skipping global package installation"
fi

# --------------------------------------------
# Install VS Code extensions
# --------------------------------------------
vscodeExts=(
  "ms-vscode-remote.remote-ssh"
  "foxundermoon.shell-format"
  "golang.go"
  "ms-azuretools.vscode-docker"
  "ms-vscode.makefile-tools"
  "shd101wyy.markdown-preview-enhanced"
  "timonwong.shellcheck"
  "vivaxy.vscode-conventional-commits"
  "charliermarsh.ruff"
  "ms-python.python"
  "tamasfe.even-better-toml"
)
for ext in "${vscodeExts[@]}"; do
  if command -v code &>/dev/null; then
    code --install-extension "$ext" || echo "⚠️ Could not install VS Code extension $ext"
  else
    echo "⚠️ VS Code CLI (code) not found, skipping extension installs"
    break
  fi
done

# --------------------------------------------
# Install Powerline fonts if missing
# --------------------------------------------
POWERLINE_MARKER="DejaVu Sans Mono for Powerline"
if ! fc-list 2>/dev/null | grep -qi "$POWERLINE_MARKER"; then
  echo ">>> Installing Powerline fonts"
  git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
  /tmp/fonts/install.sh
  rm -rf /tmp/fonts
fi

# --------------------------------------------
# Install LazyVim (backup first, idempotent)
# --------------------------------------------
NVIM_DIR="$HOME/.config/nvim"
if [ ! -f "$NVIM_DIR/lua/lazyvim/init.lua" ]; then
  echo ">>> Installing LazyVim..."
  timestamp=$(date +%Y%m%d_%H%M%S)
  [[ -d "$NVIM_DIR" ]] && mv "$NVIM_DIR" "${NVIM_DIR}_backup_$timestamp"
  rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
  git clone https://github.com/LazyVim/starter "$NVIM_DIR"
  nvim --headless "+Lazy! sync" +qa
else
  echo "✅ LazyVim already installed, skipping."
fi

# --------------------------------------------
# Generate SSH key if missing (with email prompt)
# --------------------------------------------
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo ">>> No SSH key found."

  # Prompt for email address
  while true; do
    read -rp "📧 Enter email address for SSH key (used for Git): " user_email
    read -rp "❓ Use \"$user_email\" for SSH key? [y/n]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      break
    fi
    echo "🔁 Let's try again..."
  done

  echo ">>> Generating new SSH key (ed25519)..."
  ssh-keygen -t ed25519 -C "$user_email" -f "$SSH_KEY" -N ""
  echo "✅ SSH key generated."
  echo ""
  echo "📋 SSH public key (add this to GitHub/GitLab):"
  echo "------------------------------------------------"
  cat "${SSH_KEY}.pub"
  echo "------------------------------------------------"
else
  echo "✅ SSH key already exists, skipping generation."
fi


# --------------------------------------------
# MacOS system tweaks (idempotent)
# --------------------------------------------
echo ">>> Applying macOS defaults tweaks..."
# Show all filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Disable "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Restart Finder to apply changes
killall Finder || true

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Apply changes by restarting the Dock
killall Dock || true


# --------------------------------------------
# Cleanup Homebrew and asdf
# --------------------------------------------
echo ">>> Cleaning up Homebrew and asdf..."
brew cleanup || true
asdf reshim || true

# --------------------------------------------
# Final: run topgrade in fresh zsh shell
# --------------------------------------------
echo ">>> Running topgrade in fresh login shell..."
"$BREW_ZSH" -l -c "topgrade"

# --------------------------------------------
# Manual step reminder
# --------------------------------------------
echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Restart your terminal to use the new shell"
echo "   2. Configure Git with your details:"
echo "      git config --global user.name 'Your Name'"
echo "      git config --global user.email 'your@email.com'"
echo "   3. Add your SSH key to GitHub/GitLab (key shown above)"
echo ""
echo "🧭 To update everything in future, run: topgrade"