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
declare -a zsh_tools=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions starship zoxide tldr httpie eza kubectx)
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
  grep -qxF "$line" "$ZSHRC" 2>/dev/null || echo "$line" >>"$ZSHRC"
}

# Check if custom configuration marker exists
if ! grep -q "# >>> mac-setup custom configuration >>>" "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# >>> mac-setup custom configuration >>>"
    echo "# This section is managed by the mac-setup script"
  } >>"$ZSHRC"
fi

add_to_zshrc 'eval "$(/opt/homebrew/bin/brew shellenv)"'
add_to_zshrc 'eval "$(starship init zsh)"'
add_to_zshrc 'eval "$(zoxide init zsh)"'
add_to_zshrc 'source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
add_to_zshrc 'source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
add_to_zshrc 'fpath+=("$(brew --prefix)/share/zsh-completions")'

# Configure shell history
add_to_zshrc ''
add_to_zshrc '# Shell History Configuration'
add_to_zshrc 'HISTSIZE=50000'
add_to_zshrc 'SAVEHIST=50000'
add_to_zshrc 'HISTFILE=~/.zsh_history'
add_to_zshrc 'setopt EXTENDED_HISTORY'
add_to_zshrc 'setopt HIST_IGNORE_ALL_DUPS'
add_to_zshrc 'setopt SHARE_HISTORY'
add_to_zshrc 'setopt HIST_FIND_NO_DUPS'
add_to_zshrc 'setopt HIST_IGNORE_SPACE'

# Configure navigation and directory options
add_to_zshrc ''
add_to_zshrc '# Navigation & Directory Options'
add_to_zshrc 'setopt AUTO_CD'
add_to_zshrc 'setopt AUTO_PUSHD'
add_to_zshrc 'setopt PUSHD_IGNORE_DUPS'
add_to_zshrc 'setopt PUSHD_SILENT'
add_to_zshrc 'setopt EXTENDED_GLOB'

# Configure completion options
add_to_zshrc ''
add_to_zshrc '# Completion Options'
add_to_zshrc 'zstyle ":completion:*" matcher-list "m:{a-z}={A-Za-z}"'
add_to_zshrc 'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"'
add_to_zshrc 'zstyle ":completion:*" menu select'
add_to_zshrc 'zstyle ":completion:*:*:kill:*:processes" list-colors "=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01"'
add_to_zshrc 'zstyle ":completion:*:*:*:*:processes" command "ps -u $USER -o pid,user,comm -w -w"'
add_to_zshrc ''
add_to_zshrc '# Enable expansion of globs/patterns in completion (for partial directory names)'
add_to_zshrc 'zstyle '\'':completion:*'\'' completer _expand _complete _ignored _approximate'

# Key bindings
add_to_zshrc ''
add_to_zshrc '# Key Bindings'
add_to_zshrc 'bindkey "^[[A" history-beginning-search-backward'
add_to_zshrc 'bindkey "^[[B" history-beginning-search-forward'
add_to_zshrc 'bindkey "^[[1;5C" forward-word'
add_to_zshrc 'bindkey "^[[1;5D" backward-word'

# Initialize completion system AFTER all zstyle configurations
add_to_zshrc ''
add_to_zshrc '# Initialize completion system (must be after zstyle configurations)'
add_to_zshrc 'autoload -Uz compinit && compinit'

# pay-respects isn't in homebrew-core; install via its official script.
if command -v pay-respects &>/dev/null; then
  echo "✅ pay-respects already installed, skipping"
else
  echo ">>> Installing pay-respects..."
  curl -sSfL https://raw.githubusercontent.com/iffse/pay-respects/main/install.sh | sh || echo "⚠️ Failed to install pay-respects"
fi

# Initialize pay-respects if available (installs to ~/.local/bin)
add_to_zshrc ''
add_to_zshrc '# Initialize pay-respects'
add_to_zshrc 'export PATH="$HOME/.local/bin:$PATH"'
add_to_zshrc 'command -v pay-respects &>/dev/null && eval "$(pay-respects zsh --alias)"'

# Aliases for modern tools
add_to_zshrc ''
add_to_zshrc '# Modern Tool Aliases'
add_to_zshrc 'alias ls="eza --icons=auto"'
add_to_zshrc 'alias ll="eza -lh --icons=auto --git"'
add_to_zshrc 'alias la="eza -lah --icons=auto --git"'
add_to_zshrc 'alias lt="eza --tree --level=2 --icons=auto"'
add_to_zshrc 'alias cat="bat --paging=never"'
add_to_zshrc 'alias catp="bat"'
add_to_zshrc 'alias find="fd"'
add_to_zshrc 'alias grep="rg"'
add_to_zshrc 'alias top="htop"'

# Git aliases
add_to_zshrc ''
add_to_zshrc '# Git Aliases'
add_to_zshrc 'alias g="git"'
add_to_zshrc 'alias gs="git status"'
add_to_zshrc 'alias ga="git add"'
add_to_zshrc 'alias gc="git commit"'
add_to_zshrc 'alias gp="git push"'
add_to_zshrc 'alias gl="git pull"'
add_to_zshrc 'alias gd="git diff"'
add_to_zshrc 'alias gco="git checkout"'
add_to_zshrc 'alias gb="git branch"'
add_to_zshrc 'alias glog="git log --oneline --graph --decorate"'
add_to_zshrc 'alias glg="lazygit"'

# Docker aliases
add_to_zshrc ''
add_to_zshrc '# Docker Aliases'
add_to_zshrc 'alias d="docker"'
add_to_zshrc 'alias dc="docker compose"'
add_to_zshrc 'alias dps="docker ps"'
add_to_zshrc 'alias dpsa="docker ps -a"'
add_to_zshrc 'alias di="docker images"'
add_to_zshrc 'alias dex="docker exec -it"'
add_to_zshrc 'alias dlog="docker logs -f"'
add_to_zshrc 'alias dprune="docker system prune -af --volumes"'

# Kubernetes aliases
add_to_zshrc ''
add_to_zshrc '# Kubernetes Aliases'
add_to_zshrc 'alias k="kubectl"'
add_to_zshrc 'alias kx="kubectx"'
add_to_zshrc 'alias kn="kubens"'
add_to_zshrc 'alias kgp="kubectl get pods"'
add_to_zshrc 'alias kgs="kubectl get svc"'
add_to_zshrc 'alias kgd="kubectl get deployments"'
add_to_zshrc 'alias kl="kubectl logs -f"'
add_to_zshrc 'alias ke="kubectl exec -it"'
add_to_zshrc 'alias kdesc="kubectl describe"'
add_to_zshrc 'alias kapp="kubectl apply -f"'
add_to_zshrc 'alias kdel="kubectl delete"'

# Utility functions
add_to_zshrc ''
add_to_zshrc '# Utility Functions'
add_to_zshrc 'mkcd() { mkdir -p "$1" && cd "$1"; }'
add_to_zshrc 'printclip() { local tmp; tmp="$(mktemp -t clip).pdf"; pbpaste | pandoc -o "$tmp" --pdf-engine=weasyprint && lp "$tmp"; }'

# Add extract function only if not already present
if ! grep -q "^extract() {" "$ZSHRC" 2>/dev/null; then
  cat >>"$ZSHRC" <<'EOF'
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unar "$1"        ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "Cannot extract $1" ;;
    esac
  else
    echo "$1 is not a valid file"
  fi
}
EOF
fi

add_to_zshrc 'port() { lsof -i :"$1"; }'
add_to_zshrc 'myip() { curl -s ifconfig.me; echo; }'
add_to_zshrc 'weather() { curl -s "wttr.in/${1:-}"; }'
add_to_zshrc 'gitclean() { git branch --merged | grep -v "\*" | grep -v "main\|master\|develop" | xargs -n 1 git branch -d; }'

# Add closing marker if not already present
if ! grep -q "# <<< mac-setup custom configuration <<<" "$ZSHRC" 2>/dev/null; then
  echo "# <<< mac-setup custom configuration <<<" >>"$ZSHRC"
fi

# -------------------------------------
# Homebrew apps to install
# -------------------------------------
declare -a terminal=(iterm2 tmux neovim)
declare -a toolsAlternative=(bat fd rg htop coreutils)
# chromedriver's cask fails the macOS Gatekeeper check and Homebrew disables
# it 2026-09-01, so it's deliberately left out below. If you need it, use
# Selenium Manager (bundled since Selenium 4.6, auto-downloads the matching
# driver) instead.
declare -a productivity=(
  topgrade mise cloc universal-ctags ctop curl dos2unix
  git git-extras git-lfs nmap pass shellcheck shfmt telnet
  tree wget xquartz jq yq
  docker-credential-helper fzf dive tig lazygit gh 1password-cli valkey
  unar p7zip pandoc weasyprint
)
declare -a kubernetes=(k3d k9s)
declare -a guiApps=(
  firefox google-chrome brave-browser slack
  spotify teamviewer visual-studio-code whatsapp
  docker ollama 1password pgadmin4 redis-insight
)
declare -a testTools=(
  pre-commit vale hadolint k6 grpcurl
)

# python-yq (kislyuk/yq) installs a `yq` binary that conflicts with the
# now-preferred mikefarah/yq (Go, no jq dependency) — remove the old one
# first so installing `yq` from productivity below doesn't fail.
if brew list python-yq &>/dev/null; then
  echo ">>> Removing python-yq (superseded by yq) to avoid a binary conflict..."
  brew uninstall python-yq || echo "⚠️ Failed to remove python-yq"
fi

# Install command-line tools with idempotent checking
echo ">>> Installing Homebrew packages..."
all_cli_tools=("${terminal[@]}" "${toolsAlternative[@]}" "${productivity[@]}" "${kubernetes[@]}" "${testTools[@]}")
for tool in "${all_cli_tools[@]}"; do
  if brew list "$tool" &>/dev/null; then
    echo "✅ $tool already installed, skipping"
  else
    echo ">>> Installing $tool..."
    brew install "$tool" || echo "⚠️ Failed to install $tool"
  fi
done

# Install GUI applications with idempotent checking
echo ">>> Installing GUI applications..."
for app in "${guiApps[@]}"; do
  if brew list --cask "$app" &>/dev/null; then
    echo "✅ $app already installed, skipping"
  else
    echo ">>> Installing $app..."
    brew install --cask "$app" || echo "⚠️ Failed to install $app"
  fi
done

# -------------------------------------
# Add runtime tool support to zshrc
# -------------------------------------
add_to_zshrc 'eval "$(/opt/homebrew/bin/mise activate zsh)"'
add_to_zshrc '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
add_to_zshrc 'eval "$(direnv hook zsh)"'

# -------------------------------------
# Init tools for current session
# -------------------------------------
if command -v mise &>/dev/null; then
  eval "$(/opt/homebrew/bin/mise activate bash)"
else
  echo "⚠️ mise not yet available, skipping activation for current session"
fi

# Install fzf key bindings and fuzzy completion
if [ -f "$(brew --prefix)/opt/fzf/install" ]; then
  "$(brew --prefix)/opt/fzf/install" --all || echo "⚠️ fzf install had issues"
fi

# -------------------------------------
# Helper: install mise tool+version
# -------------------------------------
install_mise_tool() {
  local tool="$1"
  local version="${2:-latest}"

  echo ">>> Installing $tool@$version with mise..."

  # Resolve aliases like "latest" or "lts" to a concrete version so the
  # installed-check below actually matches something in `mise list` output.
  local resolved_version="$version"
  if [[ ! "$version" =~ ^[0-9] ]]; then
    resolved_version="$(mise latest "$tool@$version" 2>/dev/null || mise latest "$tool" 2>/dev/null || echo "$version")"
  fi

  # Check if already installed
  if mise list "$tool" 2>/dev/null | grep -q "$resolved_version"; then
    echo "✅ $tool@$resolved_version already installed"
  else
    if ! mise install "$tool@$version"; then
      echo "⚠️ Failed to install $tool@$version, skipping"
      return 1
    fi
    echo "✅ $tool@$version installed successfully"
  fi

  # Set as global version
  echo ">>> Setting global version for $tool to $version"
  mise use -g "$tool@$version" || echo "⚠️ Could not set global version for $tool"
}

# -------------------------------------
# Install mise toolchains
# -------------------------------------
echo ">>> Installing development languages via mise..."

# Ensure mise is available before trying to use it
if ! command -v mise &>/dev/null; then
  echo "⚠️ mise not found, skipping mise tool installation"
else
  # Older mise releases have a known resolver bug that picks a broken
  # freethreaded Python build ("missing a lib directory"); keep mise
  # current to avoid it. `brew list` only checks presence, not version,
  # so this needs an explicit upgrade.
  echo ">>> Ensuring mise is up to date (was: $(mise --version 2>/dev/null))..."
  brew upgrade mise || echo "⚠️ Failed to upgrade mise, continuing with $(mise --version 2>/dev/null)"
  echo ">>> mise version now: $(mise --version 2>/dev/null)"

  # `|| true` matters here: install_mise_tool returns 1 on failure, and as
  # a bare statement under `set -e` that would silently kill the rest of
  # the script (git config, VS Code settings, SSH key gen, etc. would never
  # run). Each call already logs its own ⚠️ warning internally.
  install_mise_tool go latest || true
  install_mise_tool node lts || true
  install_mise_tool python 3.14.7 || true
  install_mise_tool java 21 || true
  install_mise_tool trivy latest || true
  install_mise_tool kubectl latest || true
  install_mise_tool helm latest || true
  install_mise_tool krew latest || true
fi

# -------------------------------------
# Clean up old asdf configuration files
# -------------------------------------
echo ">>> Cleaning up old asdf configuration files..."
if [ -f "$HOME/.tool-versions" ]; then
  timestamp=$(date +%Y%m%d_%H%M%S)
  echo ">>> Backing up ~/.tool-versions to ~/.tool-versions.asdf-backup_$timestamp"
  mv "$HOME/.tool-versions" "$HOME/.tool-versions.asdf-backup_$timestamp"
  echo "✅ Old asdf .tool-versions file backed up"
fi

if [ -d "$HOME/.asdf" ]; then
  echo ">>> Old asdf directory found at ~/.asdf (you can remove it manually if no longer needed)"
fi

# Clean up asdf references from .zshrc
if grep -q "asdf" "$HOME/.zshrc" 2>/dev/null; then
  echo ">>> Removing old asdf references from .zshrc..."
  sed -i.asdf-backup "$(date +%Y%m%d_%H%M%S)" \
    -e '/source.*asdf.*libexec\/asdf.sh/d' \
    "$HOME/.zshrc"
  echo "✅ Cleaned up .zshrc (backup created)"
fi

# -------------------------------------
# Install modern Python package managers (idempotent)
# -------------------------------------
echo ">>> Installing UV Python package manager (recommended)..."
if command -v uv &>/dev/null; then
  echo "✅ UV already installed, skipping"
elif ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  add_to_zshrc 'export PATH="$HOME/.local/bin:$PATH"'
  echo "✅ UV installed successfully"
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
if command -v mise &>/dev/null; then
  install_mise_tool direnv latest || true
else
  echo "⚠️ mise not available, skipping direnv installation via mise"
fi

# Configure direnv properly
mkdir -p ~/.config/direnv
touch ~/.config/direnv/direnvrc
grep -qxF 'export DIRENV_LOG_FORMAT=""' ~/.config/direnv/direnvrc ||
  echo 'export DIRENV_LOG_FORMAT=""' >>~/.config/direnv/direnvrc

# mise has built-in direnv support, no special integration needed
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

  # Set up commit message template
  cat >"$HOME/.gitmessage" <<'TEMPLATE'
feat: <subject>

# <body>

# Type: feat, fix, docs, style, refactor, test, chore, build

# Subject: short description (imperative mood)

# Body: detailed explanation (optional)

# Footer: optional, e.g. "refs: TICKET-123" for issue tracking

TEMPLATE
  git config --global commit.template "$HOME/.gitmessage"
  echo "✅ Git commit template configured"

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
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$settings_file" "${settings_file}.backup_${timestamp}"
    echo ">>> Backed up existing VS Code settings to ${settings_file}.backup_${timestamp}"
  fi

  # Create VS Code settings.json with sensible defaults
  cat >"$settings_file" <<'EOF'
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
  ],
  "conventionalCommits.showEditor": true,
  "conventionalCommits.autoCommit": false,
  "conventionalCommits.lineBreak": "\n",
  "conventionalCommits.promptFooter": true,
  "git.inputValidationLength": 72,
  "git.inputValidationSubjectLength": 50
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

  cat >"$starship_config" <<'EOF'
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

# Install Nerd Fonts for better Starship experience (with checking)
# (Nerd Fonts already include the Powerline glyph set Starship needs, so a
# separate powerline/fonts install is redundant and has been dropped.)
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

# Setup Git user configuration (skip if already configured)
if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
  echo "✅ Git user already configured ($(git config --global user.name) <$(git config --global user.email)>), skipping"
elif [[ -n "${GIT_EMAIL:-}" ]]; then
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
# NOTE: this suppresses Gatekeeper's warning for apps downloaded from the
# internet — a real security/convenience tradeoff, not just cosmetic.
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
# Cleanup Homebrew and mise
# --------------------------------------------
echo ">>> Cleaning up Homebrew and mise..."
brew cleanup || true
mise reshim || true

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
