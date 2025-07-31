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
echo ">>> Installing updated Bash and Zsh..."
if brew list bash &>/dev/null; then
  echo "✅ bash already installed, skipping"
else
  brew install bash || true
fi

if brew list zsh &>/dev/null; then
  echo "✅ zsh already installed, skipping"
else
  brew install zsh || true
fi

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
echo ">>> Installing Zsh tools & improvements..."
declare -a zsh_tools=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship zoxide)
for tool in "${zsh_tools[@]}"; do
  if brew list "$tool" &>/dev/null; then
    echo "✅ $tool already installed, skipping"
  else
    echo ">>> Installing $tool..."
    brew install "$tool" || echo "⚠️ Failed to install $tool"
  fi
done

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
  docker-credential-helper fzf z dive tig lazygit gh 1password-cli
)
declare -a kubernetes=(k3d k9s)
declare -a guiApps=(
  firefox google-chrome brave-browser slack
  spotify teamviewer visual-studio-code whatsapp
  docker ollama 1password
)
declare -a testTools=(
  pre-commit vale hadolint k6
)

# Install command-line tools with idempotent checking
echo ">>> Installing Homebrew packages..."
all_cli_tools=("${terminal[@]}" "${toolsAlternative[@]}" "${productivity[@]}" "${kubernetes[@]}" "${testTools[@]}")
for tool in "${all_cli_tools[@]}"; do
  if brew list "$tool" &>/dev/null; then
    echo "✅ $tool already installed, skipping"
  else
    echo ">>> Installing $tool..."
    brew install --no-quarantine "$tool" || echo "⚠️ Failed to install $tool"
  fi
done

# Install GUI applications with idempotent checking
echo ">>> Installing GUI applications..."
for app in "${guiApps[@]}"; do
  if brew list --cask "$app" &>/dev/null; then
    echo "✅ $app already installed, skipping"
  else
    echo ">>> Installing $app..."
    brew install --cask --no-quarantine "$app" || echo "⚠️ Failed to install $app"
  fi
done

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
# Install modern Python package managers (idempotent)
# -------------------------------------
echo ">>> Installing UV Python package manager (recommended)..."
if command -v uv &>/dev/null; then
  echo "✅ UV already installed, skipping"
elif ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  add_to_zshrc 'export PATH="$HOME/.cargo/bin:$PATH"'
  echo "✅ UV installed successfully"
fi

echo ">>> Installing Rye Python package manager (legacy support)..."
if command -v rye &>/dev/null; then
  echo "✅ Rye already installed, skipping"
elif ! command -v rye &>/dev/null; then
  curl -sSf https://rye.astral.sh/get | bash
  add_to_zshrc 'source "$HOME/.rye/env"'
  echo "✅ Rye installed successfully"
fi

# -------------------------------------
# Install Ruff linter and formatter (idempotent)
# -------------------------------------
echo ">>> Installing Ruff Python linter and formatter..."
if command -v ruff &>/dev/null; then
  echo "✅ Ruff already installed, skipping"
elif command -v uv &>/dev/null; then
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

# Only install krew plugins if krew is available
if command -v kubectl &>/dev/null && kubectl krew version &>/dev/null; then
  echo ">>> Installing kubectl krew plugins..."
  kubectl krew install tail || echo "✅ krew tail already installed"
else
  echo "⚠️ kubectl krew not available, skipping plugin installation"
fi

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
# Configure Git with sensible defaults and aliases
# --------------------------------------------
setup_git_config() {
  echo ">>> Setting up Git configuration..."

  # Core settings
  git config --global init.defaultBranch main
  git config --global pull.rebase true
  git config --global push.autoSetupRemote true
  git config --global core.autocrlf input
  git config --global core.editor "code --wait"
  git config --global diff.tool "vscode"
  git config --global difftool.vscode.cmd "code --wait --diff \$LOCAL \$REMOTE"
  git config --global merge.tool "vscode"
  git config --global mergetool.vscode.cmd "code --wait \$MERGED"
  git config --global rerere.enabled true

  # Useful aliases
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global alias.unstage "reset HEAD --"
  git config --global alias.last "log -1 HEAD"
  git config --global alias.visual "!gitk"
  git config --global alias.tree "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
  git config --global alias.branches "branch -a"
  git config --global alias.remotes "remote -v"
  git config --global alias.aliases "config --get-regexp alias"
  git config --global alias.amend "commit --amend --no-edit"
  git config --global alias.undo "reset --soft HEAD~1"
  git config --global alias.wip "commit -am 'WIP'"
  git config --global alias.squash "rebase -i HEAD~"
  git config --global alias.cleanup "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"
  git config --global alias.fresh "!git fetch --all && git checkout main && git pull origin main"
  git config --global alias.sync "!git fresh && git cleanup"

  echo "✅ Git configuration completed"
}

# --------------------------------------------
# Setup VS Code settings
# --------------------------------------------
setup_vscode_settings() {
  echo ">>> Setting up VS Code settings..."

  local vscode_dir="$HOME/Library/Application Support/Code/User"
  mkdir -p "$vscode_dir"

  local settings_file="$vscode_dir/settings.json"

  # Backup existing settings if they exist
  if [[ -f "$settings_file" ]]; then
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$settings_file" "${settings_file}.backup_${timestamp}"
    echo ">>> Backed up existing VS Code settings to ${settings_file}.backup_${timestamp}"
  fi

  # Create VS Code settings.json with sensible defaults
  cat > "$settings_file" << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.formatOnPaste": true,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.rulers": [120],
  "editor.wordWrap": "wordWrapColumn",
  "editor.wordWrapColumn": 120,
  "editor.minimap.enabled": false,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit",
    "source.fixAll": "explicit"
  },
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "files.exclude": {
    "**/__pycache__": true,
    "**/.pytest_cache": true,
    "**/.mypy_cache": true,
    "**/.ruff_cache": true,
    "**/node_modules": true,
    "**/.DS_Store": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/.git": true,
    "**/.svn": true,
    "**/.hg": true,
    "**/CVS": true,
    "**/.DS_Store": true,
    "**/Thumbs.db": true,
    "**/__pycache__": true,
    "**/.pytest_cache": true,
    "**/.mypy_cache": true,
    "**/.ruff_cache": true
  },
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.fontFamily": "MesloLGS NF",
  "workbench.startupEditor": "newUntitledFile",
  "workbench.editor.enablePreview": false,
  "workbench.colorTheme": "Default Dark+",
  "explorer.confirmDelete": false,
  "explorer.confirmDragAndDrop": false,
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": true,
  "python.defaultInterpreterPath": "python",
  "python.formatting.provider": "none",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.tabSize": 4,
    "editor.codeActionsOnSave": {
      "source.organizeImports.ruff": "explicit",
      "source.fixAll.ruff": "explicit"
    }
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[yaml]": {
    "editor.tabSize": 2
  },
  "[markdown]": {
    "editor.wordWrap": "on",
    "editor.quickSuggestions": {
      "comments": "off",
      "strings": "off",
      "other": "off"
    }
  },
  "ruff.organizeImports": true,
  "ruff.fixAll": true,
  "shellcheck.enable": true,
  "conventionalCommits.scopes": [
    "feat",
    "fix",
    "docs",
    "style",
    "refactor",
    "test",
    "chore"
  ]
}
EOF

  echo "✅ VS Code settings configured (existing settings backed up)"
}

# --------------------------------------------
# Setup Starship prompt configuration
# --------------------------------------------
setup_starship_config() {
  echo ">>> Setting up Starship configuration..."

  local starship_config="$HOME/.config/starship.toml"
  mkdir -p "$(dirname "$starship_config")"

  cat > "$starship_config" << 'EOF'
# Starship configuration
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$docker_context\
$kubernetes\
$python\
$nodejs\
$golang\
$java\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"
style = "bold cyan"

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
deleted = "✘"
modified = "!"
staged = "+"
untracked = "?"
style = "bold yellow"

[python]
symbol = " "
python_binary = ["python", "python3", "python2"]
style = "bold green"

[nodejs]
symbol = " "
style = "bold green"

[golang]
symbol = " "
style = "bold cyan"

[java]
symbol = " "
style = "bold red"

[docker_context]
symbol = " "
style = "bold blue"

[kubernetes]
disabled = false
symbol = "⎈ "
style = "bold blue"

[cmd_duration]
min_time = 2_000
format = "took [$duration](bold yellow)"

[username]
style_user = "bold dimmed blue"
show_always = false

[hostname]
ssh_only = true
style = "bold dimmed green"
EOF

  echo "✅ Starship configuration created"
}

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
# Install VS Code extensions (idempotent)
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
  "esbenp.prettier-vscode"
  "redhat.vscode-yaml"
  "ms-vscode-remote.remote-containers"
)

if command -v code &>/dev/null; then
  echo ">>> Installing VS Code extensions..."
  # Get list of already installed extensions once
  installed_extensions=$(code --list-extensions 2>/dev/null || echo "")

  for ext in "${vscodeExts[@]}"; do
    if echo "$installed_extensions" | grep -q "^${ext}$"; then
      echo "✅ $ext already installed, skipping"
    else
      echo ">>> Installing VS Code extension: $ext"
      if ! code --install-extension "$ext" 2>/dev/null; then
        echo "⚠️ Could not install VS Code extension $ext"
      fi
    fi
  done
else
  echo "⚠️ VS Code CLI (code) not found, skipping extension installs"
fi

# --------------------------------------------
# Install Powerline fonts if missing (idempotent)
# --------------------------------------------
POWERLINE_MARKER="DejaVu Sans Mono for Powerline"
if fc-list 2>/dev/null | grep -qi "$POWERLINE_MARKER"; then
  echo "✅ Powerline fonts already installed, skipping"
else
  echo ">>> Installing Powerline fonts"
  if [[ -d /tmp/fonts ]]; then
    rm -rf /tmp/fonts
  fi
  git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
  cd /tmp/fonts && ./install.sh
  cd - > /dev/null
  rm -rf /tmp/fonts
  echo "✅ Powerline fonts installed"
fi

# Install Nerd Fonts for better Starship experience (with checking)
echo ">>> Installing Nerd Fonts..."
# Note: homebrew/cask-fonts is deprecated, but individual font casks still work
if brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
  echo "✅ font-meslo-lg-nerd-font already installed, skipping"
else
  echo ">>> Installing font-meslo-lg-nerd-font..."
  brew install --cask font-meslo-lg-nerd-font || echo "⚠️ Failed to install Nerd Font"
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

  # Store email for Git configuration
  GIT_EMAIL="$user_email"
else
  echo "✅ SSH key already exists, skipping generation."
  # Try to extract email from existing SSH key
  GIT_EMAIL=$(ssh-keygen -l -f "${SSH_KEY}.pub" 2>/dev/null | grep -o '[^[:space:]]*@[^[:space:]]*' || echo "")
fi

# Setup Git user configuration
if [[ -n "${GIT_EMAIL:-}" ]]; then
  echo ">>> Configuring Git user settings..."
  read -rp "📝 Enter your full name for Git commits: " git_name
  git config --global user.email "$GIT_EMAIL"
  git config --global user.name "$git_name"
  echo "✅ Git user configuration completed"
fi

# Run Git configuration setup
setup_git_config

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
defaults write NSGlobalDomain KeyRepeat -int 3
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Restart Finder to apply changes
killall Finder || true

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Apply changes by restarting the Dock
killall Dock || true

# --------------------------------------------
# Setup configuration files
# --------------------------------------------
setup_vscode_settings
setup_starship_config

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
echo "   1. Restart your terminal to use the new shell and see the Starship prompt"
echo "   2. Your Git configuration has been set up with useful aliases"
echo "   3. VS Code settings have been configured with Python-focused defaults"
echo "   4. Add your SSH key to GitHub/GitLab (key shown above)"
echo ""
echo "🧭 Useful Git aliases added:"
echo "   git tree    - Pretty commit graph"
echo "   git sync    - Fetch, checkout main, pull, cleanup merged branches"
echo "   git wip     - Quick work-in-progress commit"
echo "   git aliases - Show all configured aliases"
echo ""
echo "🔧 To update everything in future, run: topgrade"
