#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------
# Install Homebrew (Apple Silicon only)
# ----------------------------------------
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH for this script session
eval "$("$(which brew)" shellenv)"

# ------------------------------------------------
# Install Bash 5.x via Homebrew and allow-list
# ------------------------------------------------
brew install bash
BREW_BASH="$(brew --prefix)/bin/bash"
if ! grep -Fxq "$BREW_BASH" /etc/shells; then
  echo "$BREW_BASH" | sudo tee -a /etc/shells
fi

# -----------------------------------------------------
# Define categorized packages to install via Homebrew
# -----------------------------------------------------
declare -a terminal=(
  "iterm2" # Terminal emulator
  "tmux"   # Terminal multiplexer
  "neovim" # Vim-based editor
)

declare -a toolsAlternative=(
  "lsd"  # ls replacement with pretty colors
  "bat"  # cat with syntax highlighting
  "fd"   # find ultra-fast alternative
  "rg"   # ripgrep, grep on steroids
  "htop" # interactive process viewer
)

declare -a productivity=(
  "topgrade"                 # unified updater
  "asdf"                     # version manager
  "cloc"                     # code line counter
  "chromedriver"             # Chrome WebDriver
  "universal-ctags"          # code symbol indexer
  "ctop"                     # live container metrics
  "curl"                     # data transfer
  "dos2unix"                 # remove Windows line endings
  "docker-compose"           # container orchestration
  "git"                      # version control
  "git-extras"               # useful Git extensions
  "nmap"                     # network scanner
  "pass"                     # password manager
  "shellcheck"              # shell script linter
  "telnet"                   # network debugging tool
  "the_silver_searcher"      # fast code search
  "tree"                     # directory tree visualizer
  "wget"                     # file downloader
  "xquartz"                  # X11 for macOS
  "jq"                       # JSON processor
  "python-yq"                # YAML processor
  "docker-credential-helper" # credential storage for Docker
  "fzf"                      # fuzzy finder
  "z"                        # directory jumper
  "dive"                     # Docker image explorer
  "tig"                      # text-mode Git UI
)

declare -a kubernetes=(
  "k3d" # Kubernetes in Docker
  "k9s" # CLI Kubernetes dashboard
)

declare -a guiApps=(
  "firefox"            # web browser
  "google-chrome"      # web browser
  "brave-browser"      # privacy-focused browser
  "slack"              # team chat
  "spotify"            # music streaming
  "teamviewer"         # remote desktop
  "visual-studio-code" # code editor
  "whatsapp"           # messaging app
)

# -------------------------------------
# Install all apps and tools via brew
# -------------------------------------
brew install --no-quarantine "${terminal[@]}" \
  "${toolsAlternative[@]}" \
  "${productivity[@]}" \
  "${kubernetes[@]}" \
  "${guiApps[@]}"

# ----------------------------------------------
# Update shell config for zsh (default shell)
# ----------------------------------------------
ZSHRC="$HOME/.zshrc"

# Load asdf
ASDF_INIT='source "$(brew --prefix asdf)/libexec/asdf.sh"'
grep -qxF "$ASDF_INIT" "$ZSHRC" || echo "$ASDF_INIT" >> "$ZSHRC"

# Load fzf if installed
FZF_INIT='[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
grep -qxF "$FZF_INIT" "$ZSHRC" || echo "$FZF_INIT" >> "$ZSHRC"

# Enable direnv
DIRENV_INIT='eval "$(direnv hook zsh)"'
grep -qxF "$DIRENV_INIT" "$ZSHRC" || echo "$DIRENV_INIT" >> "$ZSHRC"

# ----------------------------------------
# Source asdf & install fzf extras now
# ----------------------------------------
source "$(brew --prefix asdf)/libexec/asdf.sh"
"$(brew --prefix)/opt/fzf/install" --all

# ------------------------------------------------
# Helper to install asdf plugins with defaults
# ------------------------------------------------
install_asdf_plugin() {
  plugin="$1"
  repo="$2"
  version="${3:-latest}"
  if ! asdf plugin-list | grep -qx "$plugin"; then
    asdf plugin-add "$plugin" "$repo"
  fi
  asdf install "$plugin" "$version"
  asdf global "$plugin" "$version"
}

# ----------------------------------------
# Install common asdf plugins & toolchains
# ----------------------------------------
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
export PATH="${PATH}:${HOME}/.krew/bin"
grep -qxF 'export PATH="$HOME/.krew/bin:$PATH"' "$ZSHRC" || echo 'export PATH="$HOME/.krew/bin:$PATH"' >> "$ZSHRC"
kubectl krew install tail

# --------------------------------------------
# Set up direnv with latest version via asdf
# --------------------------------------------
install_asdf_plugin direnv "" latest
asdf direnv setup --shell zsh --version latest

# Silence direnv logs
mkdir -p ~/.config/direnv
grep -qxF 'export DIRENV_LOG_FORMAT=""' ~/.config/direnv/direnvrc ||
  echo 'export DIRENV_LOG_FORMAT=""' >>~/.config/direnv/direnvrc

# Enable direnv in current directory
touch ~/.envrc
grep -qxF 'use asdf' ~/.envrc || echo 'use asdf' >>~/.envrc

# --------------------------------------------
# Upgrade npm and install global CLI tools
# --------------------------------------------
npm install -g npm@latest meta git-open

# -------------------------------------
# 🧩 Install VS Code extensions via CLI
# -------------------------------------
vscodeExts=(
  "ms-vscode-remote.remote-ssh"         # Remote SSH development
  "foxundermoon.shell-format"           # Shell script formatter
  "golang.go"                           # Go language support
  "ms-azuretools.vscode-docker"         # Docker + Azure support
  "ms-vscode.makefile-tools"            # Makefile language tools
  "shd101wyy.markdown-preview-enhanced" # Markdown live preview
  "timonwong.shellcheck"                # Shell linting via ShellCheck
  "znck.grammarly"                      # Grammarly integration
  "donjayamanne.python-extension-pack"  # Python extensions
  "d-biehl.robotcode"                   # Robot Framework support
  "vivaxy.vscode-conventional-commits"  # Commit message formatting
  "charliermarsh.ruff"                  # Fast Python linter (Rust)
)
for ext in "${vscodeExts[@]}"; do
  code --install-extension "$ext" || echo "⚠️ Could not install VS Code extension $ext"
done

# ----------------------------------------
# Install Powerline fonts for terminals
# ----------------------------------------
FONTS_DIR="$HOME/Library/Fonts"
if [[ ! -d "$FONTS_DIR" ]]; then
  echo ">>> Installing Powerline fonts"
  git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
  /tmp/fonts/install.sh
  rm -rf /tmp/fonts
fi

# --------------------------------------------------
# Run topgrade in a *new login shell* (zsh-based)
# --------------------------------------------------
echo ">>> Running topgrade in a fresh login shell"
/bin/zsh -l -c "topgrade"

# --------------------------------------------------
# Final note for manual install
# --------------------------------------------------
echo ">>> Please manually install Docker Desktop"
