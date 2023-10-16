#!/bin/bash

if ! [ -x "$(command -v brew)" ]; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

shell=zsh
while true; do
  read -r -p '>>> What shell are you using? bash or [zsh]: ' answer
  answer=${answer:-zsh}
  case "$answer" in
  zsh)
    shell=zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    grep -qxF '. $(brew --prefix)/opt/asdf/libexec/asdf.sh' ~/.zshrc || echo '. $(brew --prefix)/opt/asdf/libexec/asdf.sh' >>~/.zshrc
    grep -qxF "export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'" ~/.zshrc || echo "export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'" >>~/.zshrc
    grep -qxF 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"' ~/.zshrc || echo 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"' >>~/.zshrc
    grep -qxF '. $(brew --prefix)/etc/profile.d/z.sh' ~/.zshrc || echo '. $(brew --prefix)/etc/profile.d/z.sh' >>~/.zshrc
    grep -qxF 'export PATH="${PATH}:${HOME}/.krew/bin"' ~/.zshrc || echo 'export PATH="${PATH}:${HOME}/.krew/bin"' >>~/.zshrc
    break
    ;;
  bash)
    shell=bash
    touch ~/.bashrc
    touch ~/.bash_profile
    grep -qxF '. $(brew --prefix)/opt/asdf/libexec/asdf.sh' ~/.bash_profile || echo '. $(brew --prefix)/opt/asdf/libexec/asdf.sh' >>~/.bash_profile
    grep -qxF '. $(brew --prefix)/etc/profile.d/z.sh' ~/.bash_profile || echo '. $(brew --prefix)/etc/profile.d/z.sh' >>~/.bash_profile
    grep -qxF 'export PATH="${PATH}:${HOME}/.krew/bin"' ~/.bash_profile || echo 'export PATH="${PATH}:${HOME}/.krew/bin"' >>~/.bash_profile
    break
    ;;
  *)
    printf "%s\n" 'Answer either “zsh” or “bash”.'
    ;;
  esac
done

echo ">>> Configured for $shell"

declare -a terminal=(
  "bash"   # Bourne-again SHell, a UNIX command interpreter - https://www.gnu.org/software/bash/
  "zsh"    # UNIX shell (command interpreter) - https://www.zsh.org/
  "iterm2" # terminal emulator - https://www.iterm2.com/
  "tmux"   # terminal multiplexer - https://github.com/tmux/tmux
  "neovim" # Vim-based text editor - https://neovim.io/
)

declare -a toolsAlternative=(
  "lsd"  # instead of ls - https://github.com/Peltoche/lsd
  "bat"  # instead of cat - https://github.com/sharkdp/bat
  "fd"   # instead of find - https://github.com/sharkdp/fd
  "rg"   # instead of grep - https://github.com/BurntSushi/ripgrep
  "htop" # instead of top - https://htop.dev/
)

declare -a productivity=(
  "topgrade"                 # system updater - https://github.com/r-darwish/topgrade
  "asdf"                     # software tools version manager - https://github.com/asdf-vm/asdf
  "cloc"                     # count lines of code - https://github.com/AlDanial/cloc
  "chromedriver"             # automated testing of webapps for Google Chrome - https://sites.google.com/chromium.org/driver/
  "universal-ctags"          # maintained implementation of ctags - https://github.com/universal-ctags/ctags
  "ctop"                     # Top-like interface for container metrics - https://github.com/bcicen/ctop
  "curl"                     # Get a file from an HTTP, HTTPS or FTP server - https://curl.se
  "dos2unix"                 # Convert text between DOS, UNIX, and Mac formats - https://waterlan.home.xs4all.nl/dos2unix.html
  "docker-compose"           # Isolated development environments using Docker - https://docs.docker.com/compose/
  "git"                      # Distributed revision control system - https://git-scm.com
  "git-extras"               # Small git utilities - https://github.com/tj/git-extras
  "nmap"                     # Port scanning utility - https://nmap.org/
  "pass"                     # Password manager - https://www.passwordstore.org/
  "shellcheck"               # Shell Linter - https://www.shellcheck.net/
  "telnet"                   # Telnet - User interface to the TELNET protocol
  "the_silver_searcher"      # Code-search similar to ack - https://github.com/ggreer/the_silver_searcher
  "tree"                     # Display directories as trees - http://mama.indstate.edu/users/ice/tree/
  "wget"                     # Internet file retriever - https://www.gnu.org/software/wget/
  "xquartz"                  # Open-source version of the X.Org X Window System - https://www.xquartz.org/
  "jq"                       # Lightweight and flexible command-line JSON processor - https://stedolan.github.io/jq/
  "python-yq"               # Command-line YAML processor - https://kislyuk.github.io/yq/
  "docker-credential-helper" # macOS Credential Helper for Docker - https://github.com/docker/docker-credential-helpers
  "fzf"                      # Command-line fuzzy finder written in Go - https://github.com/junegunn/fzf
  "z"                        # Tracks your most used directories, based on 'frecency' - https://github.com/rupa/z
  "dive"                     # Tool for exploring each layer in a docker image - https://github.com/wagoodman/dive
  "tig"                      # text-mode interface for Git - http://jonas.github.io/tig/
)

# most kubernetes tools are versioned using asdf, see below.
declare -a kubernetes=(
  "k3d" # Kubernetes cluster manager - https://k3d.io
  "k9s" # Kubernetes CLI To Manage Clusters - https://k9scli.io/
)

declare -a guiApps=(
  #  "dropbox"            # Client for the Dropbox cloud storage service - https://www.dropbox.com/
  #  "docker"             # App to build and share containerized applications and microservices - https://www.docker.com/products/docker-desktop
  "firefox"            # Web browser - https://www.mozilla.org/firefox/
  "google-chrome"      # Web browser - https://www.google.com/chrome/
  "kindle"             # Interface for reading and syncing eBooks - https://www.amazon.com/gp/digital/fiona/kcp-landing-page
  "skype"              # Video chat, voice call and instant messaging application - https://www.skype.com/
  "slack"              # Team communication and collaboration software - https://slack.com/
  "spotify"            # Music streaming service - https://www.spotify.com/
  "teamviewer"         # Remote access and connectivity software focused on security - https://www.teamviewer.com/
  "visual-studio-code" # Open-source code editor - https://code.visualstudio.com/
  "whatsapp"           # Desktop client for WhatsApp - https://www.whatsapp.com/
  # "virtualbox"         # Virtualizer for x86 hardware - https://www.virtualbox.org/
)

# https://www.macstadium.com/blog/install-asdf-on-macos - tcl-tk required to resolve tk issue on osx
declare -a pythonDeps=(
  "tcl-tk"   # Tool Command Language - https://www.tcl-lang.org
  "readline" # Library for commandline editing - https://tiswww.case.edu/php/chet/readline/rltop.html
  "zlib"     # General-purpose lossless data-compression library - https://zlib.net/
  "openssl"  # Cryptography and SSL/TLS Toolkit - https://openssl.org/
  "sqlite3"  # Command-line interface for SQLite - https://sqlite.org/index.html
  "xz"       # General-purpose data compression with high compression ratio - https://tukaani.org/xz/
)

# brew tap "${taps[@]}"
brew install --no-quarantine "${terminal[@]}"
brew install --no-quarantine "${toolsAlternative[@]}"
brew install --no-quarantine "${pythonDeps[@]}"
brew install --no-quarantine "${productivity[@]}"
brew install --no-quarantine "${kubernetes[@]}"
brew install --no-quarantine "${guiApps[@]}"

touch ~/.asdfrc
grep -qxF 'java_macos_integration_enable = yes' ~/.asdfrc || echo 'java_macos_integration_enable = yes' >>~/.asdfrc
. $(brew --prefix)/opt/asdf/libexec/asdf.sh

$(brew --prefix)/opt/fzf/install --all

GO_VER=latest
asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
asdf install golang $GO_VER
asdf global golang $GO_VER

NODE_VER=lts-fermium
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs $NODE_VER
asdf global nodejs $NODE_VER

PYTHON_VER=latest
asdf plugin-add python https://github.com/danhper/asdf-python.git
asdf install python $PYTHON_VER
asdf global python $PYTHON_VER

JAVA_VER=openjdk-18.0.1
asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf install java $JAVA_VER
asdf global java $JAVA_VER

POETRY_VER=1.3.2
asdf plugin-add poetry https://github.com/asdf-community/asdf-poetry.git
asdf install poetry $POETRY_VER
asdf global poetry $POETRY_VER

TRIVY_VER=latest
asdf plugin-add trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git
asdf install trivy $TRIVY_VER
asdf global trivy $TRIVY_VER

KUBECTL_VER=1.25.0
asdf plugin-add kubectl https://github.com/Banno/asdf-kubectl.git
asdf install kubectl $KUBECTL_VER
asdf global kubectl $KUBECTL_VER

HELM_VER=3.8.2
asdf plugin-add helm https://github.com/Antiarchitect/asdf-helm.git
asdf install helm $HELM_VER
asdf global helm $HELM_VER

KREW_VER=v0.4.3
asdf plugin-add krew https://github.com/nlamirault/asdf-krew.git
asdf install krew $KREW_VER
asdf global krew $KREW_VER
export PATH="${PATH}:${HOME}/.krew/bin"
krew install krew
declare -a krews=(
  "tail" # streams logs from all containers of all matched pods
)
kubectl krew install "${krews[@]}"

DIRENV_VER=latest
asdf plugin-add direnv
# run the right setup for your shell
if [ "$shell" == "bash" ]; then
  asdf direnv setup --shell bash --version latest
else
  asdf direnv setup --shell zsh --version latest
fi

# turn off direnv logging
mkdir -p ~/.config/direnv
grep -qxF 'export DIRENV_LOG_FORMAT=""' ~/.config/direnv/direnvrc || echo 'export DIRENV_LOG_FORMAT=""' >>~/.config/direnv/direnvrc

touch ~/.envrc
grep -qxF 'use asdf' ~/.envrc || echo 'use asdf' >>~/.envrc

# on Apple silcon, needed update before installing meta
npm install -g npm@latest

# install node binaries
declare -a nodeModules=(
  "meta"     # tool for managing multi-projects - https://github.com/mateodelnorte/meta-npm
  "git-open" # Type git open to open the repo website (GitHub, GitLab, Bitbucket) in your browser. - https://github.com/paulirish/git-open
)
npm i -g "${nodeModules[@]}"

# install vs code extensions
declare -a vscodeExts=(
  "ms-vscode-remote.remote-ssh" # Remote - use any remote machine with a SSH server as your development environment - https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh
  "foxundermoon.shell-format"
  "golang.go"
  "ms-azuretools.vscode-docker"
  "ms-vscode.makefile-tools"
  "shd101wyy.markdown-preview-enhanced"
  "timonwong.shellcheck"
  "znck.grammarly"
  "ms-python.python"
  "d-biehl.robotcode"
  "vivaxy.vscode-conventional-commits"
)
code --install-extension "${vscodeExts[@]}"

FONTS_DIR="$HOME/Library/Fonts"
if [ ! -d "$FONTS_DIR" ]; then
  echo ">>> Installing powerline fonts in ${FONTS_DIR} useful for on my zsh themes"
  git clone https://github.com/powerline/fonts.git --depth=1
  cd fonts || exit
  ./install.sh
  cd ..
  rm -rf fonts
fi

echo ">>> Dry run of topgrade, checking to see if software needs updated"
topgrade -n

echo ">>> install docker and dropbox manually"
