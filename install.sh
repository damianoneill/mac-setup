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

# ----------------------------------------
# Install updated Bash, but use Zsh as default shell
# ----------------------------------------
brew install bash || true
BREW_BASH="$(brew --prefix)/bin/bash"
if ! grep -Fxq "$BREW_BASH" /etc/shells; then
  echo "$BREW_BASH" | sudo tee -a /etc/shells
fi

if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo ">>> Setting default shell to zsh..."
  chsh -s "$(which zsh)"
else
  echo "✅ Default shell is already zsh."
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
  docker-compose git git-extras nmap pass shellcheck telnet
  the_silver_searcher tree wget xquartz jq python-yq
  docker-credential-helper fzf z dive tig
)
declare -a kubernetes=(k3d k9s)
declare -a guiApps=(
  firefox lazygit google-chrome brave-browser slack
  spotify teamviewer visual-studio-code whatsapp
)
declare -a testTools=(
  pre-commit vale hadolint
)

# Fix: combine all arrays properly for one brew install command
brew install --no-quarantine "${terminal[@]}" \
  "${toolsAlternative[@]}" \
  "${productivity[@]}" \
  "${kubernetes[@]}" \
  "${guiApps[@]}" \
  "${testTools[@]}" || true

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
  if ! asdf plugin-list | grep -qx "$plugin"; then
    asdf plugin-add "$plugin" "$repo"
  fi
  if ! asdf list "$plugin" | grep -qx "$version"; then
    asdf install "$plugin" "$version"
  fi
  asdf global "$plugin" "$version"
}

# -------------------------------------
# Install asdf toolchains (latest by default)
# -------------------------------------
install_asdf_plugin golang https://github.com/kennyp/asdf-golang.git
install_asdf_plugin nodejs https://github.com/asdf-vm/asdf-nodejs.git
install_asdf_plugin python https://github.com/danhper/asdf-python.git
install_asdf_plugin java https://github.com/halcyon/asdf-java.git
install_asdf_plugin poetry https://github.com/asdf-community/asdf-poetry.git
install_asdf_plugin trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git
install_asdf_plugin kubectl https://github.com/Banno/asdf-kubectl.git
install_asdf_plugin helm https://github.com/Antiarchitect/asdf-helm.git
install_asdf_plugin krew https://github.com/nlamirault/asdf-krew.git

# -----------------------------------
# Enable kubectl krew plugin support
# -----------------------------------
export PATH="${HOME}/.krew/bin:$PATH"
add_to_zshrc 'export PATH="$HOME/.krew/bin:$PATH"'
kubectl krew install tail || echo "krew tail already installed"

# -----------------------------------
# Setup direnv and quiet output
# -----------------------------------
install_asdf_plugin direnv "" latest
asdf direnv setup --shell zsh --version latest

mkdir -p ~/.config/direnv
grep -qxF 'export DIRENV_LOG_FORMAT=""' ~/.config/direnv/direnvrc ||
  echo 'export DIRENV_LOG_FORMAT=""' >>~/.config/direnv/direnvrc

touch ~/.envrc
grep -qxF 'use asdf' ~/.envrc || echo 'use asdf' >>~/.envrc

# --------------------------------------------
# Upgrade npm and install global tools
# --------------------------------------------
npm install -g npm@latest meta git-open typescript eslint prettier yarn || true

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
  "znck.grammarly"
  "donjayamanne.python-extension-pack"
  "d-biehl.robotcode"
  "vivaxy.vscode-conventional-commits"
  "charliermarsh.ruff"
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
# Generate SSH key if missing
# --------------------------------------------
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo ">>> Generating new SSH key (ed25519)..."
  ssh-keygen -t ed25519 -C "your_email@example.com" -f "$SSH_KEY" -N ""
  echo ">>> SSH public key (add to GitHub/GitLab):"
  cat "${SSH_KEY}.pub"
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

# Disable “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Restart Finder to apply changes
killall Finder || true

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
/bin/zsh -l -c "topgrade"

# --------------------------------------------
# Manual step reminder
# --------------------------------------------
echo "🧭 Please manually install Docker Desktop (GUI app)"
