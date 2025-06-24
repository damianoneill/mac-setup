#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Install Homebrew (Apple Silicon only)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Put Homebrew on PATH
eval "$("$(which brew)" shellenv)"

# Install Bash 5.x via Homebrew, allow-list it, and switch default shell
brew install bash
BREW_BASH="$(brew --prefix)/bin/bash"
if ! grep -Fxq "$BREW_BASH" /etc/shells; then
  echo "$BREW_BASH" | sudo tee -a /etc/shells
fi
chsh -s "$BREW_BASH"
echo ">>> Default shell set to $BREW_BASH (Bash $(bash --version | head -n1))"

# 🛠️ Tools categories with comments for clarity
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
  "shellcheck"               # shell script linter
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

# Install all via Homebrew
brew install --no-quarantine "${terminal[@]}" \
  "${toolsAlternative[@]}" \
  "${productivity[@]}" \
  "${kubernetes[@]}" \
  "${guiApps[@]}"

# Source asdf & run fzf installer
source "$(brew --prefix)/opt/asdf/libexec/asdf.sh"
"$(brew --prefix)/opt/fzf/install" --all

# Helper to install asdf plugins safely
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

install_asdf_plugin golang https://github.com/kennyp/asdf-golang.git
install_asdf_plugin nodejs https://github.com/asdf-vm/asdf-nodejs.git
install_asdf_plugin python https://github.com/danhper/asdf-python.git
install_asdf_plugin java https://github.com/halcyon/asdf-java.git
install_asdf_plugin poetry https://github.com/asdf-community/asdf-poetry.git
install_asdf_plugin trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git
install_asdf_plugin kubectl https://github.com/Banno/asdf-kubectl.git
install_asdf_plugin helm https://github.com/Antiarchitect/asdf-helm.git
install_asdf_plugin krew https://github.com/nlamirault/asdf-krew.git

export PATH="${PATH}:${HOME}/.krew/bin"
kubectl krew install tail

# Set up direnv via asdf + logging off
install_asdf_plugin direnv "" latest
asdf direnv setup --shell bash --version latest
mkdir -p ~/.config/direnv
grep -qxF 'export DIRENV_LOG_FORMAT=""' ~/.config/direnv/direnvrc ||
  echo 'export DIRENV_LOG_FORMAT=""' >>~/.config/direnv/direnvrc
touch ~/.envrc
grep -qxF 'use asdf' ~/.envrc || echo 'use asdf' >>~/.envrc

# Update npm and install global node tools
npm install -g npm@latest meta git-open

# Install VS Code extensions
vscodeExts=(
  "ms-vscode-remote.remote-ssh"         # Develop directly on remote machines via SSH
  "foxundermoon.shell-format"           # Formats shell scripts (e.g., YAML, Bash)
  "golang.go"                           # Go language support: IntelliSense, debugging, code navigation
  "ms-azuretools.vscode-docker"         # Docker and Azure Container tooling
  "ms-vscode.makefile-tools"            # Provides IntelliSense and build support for Makefiles
  "shd101wyy.markdown-preview-enhanced" # Rich Markdown preview with diagram support and LaTeX
  "timonwong.shellcheck"                # Integrates ShellCheck linting into VS Code
  "znck.grammarly"                      # Grammarly integration for spelling and grammar checking
  "donjayamanne.python-extension-pack"  # Bundled set of essential Python extensions
  "d-biehl.robotcode"                   # Support and language features for Robot Framework
  "vivaxy.vscode-conventional-commits"  # Enforces Conventional Commits standard
  "charliermarsh.ruff"                  # Fast Python linter & formatter (Rust-based)
)
for ext in "${vscodeExts[@]}"; do
  code --install-extension "$ext" || echo "⚠️ Could not install VS Code extension $ext"
done

# Install Powerline fonts if needed
FONTS_DIR="$HOME/Library/Fonts"
if [[ ! -d "$FONTS_DIR" ]]; then
  echo ">>> Installing Powerline fonts"
  git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
  /tmp/fonts/install.sh
  rm -rf /tmp/fonts
fi

echo ">>> Dry-run topgrade"
topgrade -n

echo ">>> Please manually install Docker Desktop"
