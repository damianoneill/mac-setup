#!/bin/bash

if ! [ -x "$(command -v brew)" ]; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

shell=zsh
while true; do
  read -r -p '>>> What shell are you using? bash or [zsh]: ' answer
  answer=${answer:-zsh}
  case "$answer" in
  zsh)
    shell=zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    grep -qxF "export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'" ~/.zshrc || echo "export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'" >>~/.zshrc
    grep -qxF 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"' ~/.zshrc || echo 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"' >>~/.zshrc
    break
    ;;
  bash)
    shell=bash
    touch ~/.bashrc
    touch ~/.bash_profile
    break
    ;;
  *)
    printf "%s\n" 'Answer either “zsh” or “bash”.'
    ;;
  esac
done

echo ">>> Configured for $shell"

# declare -a taps=(

# )

declare -a terminal=(
  "zsh"       # UNIX shell (command interpreter) - https://www.zsh.org/
  "iterm2" # terminal emulator - https://www.iterm2.com/
  "tmux"      # terminal multiplexer - https://github.com/tmux/tmux
  "neovim"    # Vim-based text editor - https://neovim.io/
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
  "universal-ctags"          # maintained implementation of ctags - https://github.com/universal-ctags/ctags
  "ctop"                     # Top-like interface for container metrics - https://github.com/bcicen/ctop
  "curl"                     # Get a file from an HTTP, HTTPS or FTP server - https://curl.se
  "dos2unix"                 # Convert text between DOS, UNIX, and Mac formats - https://waterlan.home.xs4all.nl/dos2unix.html
  "git"                      # Distributed revision control system - https://git-scm.com
  "git-extras"               # Small git utilities - https://github.com/tj/git-extras
  "nmap"                     # Port scanning utility - https://nmap.org/
  "pass"                     # Password manager - https://www.passwordstore.org/
  "tree"                     # Display directories as trees - http://mama.indstate.edu/users/ice/tree/
  "wget"                     # Internet file retriever - https://www.gnu.org/software/wget/
  "xquartz"                  # Open-source version of the X.Org X Window System - https://www.xquartz.org/
  "jq"                       # Lightweight and flexible command-line JSON processor - https://stedolan.github.io/jq/
  "docker-credential-helper" # macOS Credential Helper for Docker - https://github.com/docker/docker-credential-helpers
  "fzf"                      # Command-line fuzzy finder written in Go - https://github.com/junegunn/fzf
)

# most kubernetes tools are versioned using asdf, see below.
declare -a kubernetes=(
  "k9s" # Kubernetes CLI To Manage Clusters - https://k9scli.io/
)

declare -a guiApps=(
  "dropbox"            # Client for the Dropbox cloud storage service - https://www.dropbox.com/
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

# brew tap "${taps[@]}"
brew install --no-quarantine "${terminal[@]}"
brew install --no-quarantine "${toolsAlternative[@]}"
brew install --no-quarantine "${productivity[@]}"
brew install --no-quarantine "${kubernetes[@]}"
brew install --no-quarantine "${guiApps[@]}"

touch ~/.asdfrc
grep -qxF 'java_macos_integration_enable = yes' ~/.asdfrc || echo 'java_macos_integration_enable = yes' >>~/.asdfrc
. $(brew --prefix)/opt/asdf/libexec/asdf.sh

$(brew --prefix)/opt/fzf/install --all

GO_VER=1.17.6
asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
asdf install golang $GO_VER
asdf global golang $GO_VER

NODE_VER=lts-fermium
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs $NODE_VER
asdf global nodejs $NODE_VER

PYTHON_VER=3.10.2
asdf plugin-add python https://github.com/danhper/asdf-python.git
asdf install python $PYTHON_VER
asdf global python $PYTHON_VER

KUBECTL_VER=1.23.1
asdf plugin-add kubectl https://github.com/Banno/asdf-kubectl.git
asdf install kubectl $KUBECTL_VER
asdf global kubectl $KUBECTL_VER

# install vs code extensions
declare -a vscodeExts=(
  "ms-vscode-remote.remote-ssh" # Remote - use any remote machine with a SSH server as your development environment - https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh
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
