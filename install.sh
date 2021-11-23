#!/bin/bash

if ! [ -x "$(command -v brew)" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# make sure profile exists
touch ~/.bash_profile

# upgrade bash version && add completion
grep -qxF '/usr/local/bin/bash' /etc/shells
if [ $? -ne 0 ]; then
  brew install bash
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells
  chsh -s /usr/local/bin/bash
fi
brew install bash-completion 
grep -qxF '[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"'  ~/.bash_profile
if [ $? -ne 0 ]; then
cat <<EOT >> ~/.bash_profile
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
EOT
fi


brew install ag autojump bash-git-prompt cloc ctags ctop curl derailed/k9s/k9s dos2unix fasd git git-extras git-flow go helmfile hub htop httpie kubectl kubernetes-cli net-snmp nmap node nvm openssl pass pyenv rpm socat ssh-copy-id the_silver_searcher tig tiff2png tmux tree vim wget xquartz
brew install chicken cyberduck docker dropbox balenaetcher firefox google-chrome iterm2 java kindle skype slack spotify teamviewer vagrant visual-studio-code whatsapp opera virtualbox

# add completions for the above applications
grep -qxF 'source <(kubectl completion bash)'  ~/.bash_profile
if [ $? -ne 0 ]; then
cat <<EOT >> ~/.bash_profile
source <(kubectl completion bash)
if [ -f "/usr/local/opt/bash-git-prompt/share/gitprompt.sh" ]; then
    __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
    source "/usr/local/opt/bash-git-prompt/share/gitprompt.sh"
fi
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion
EOT
fi

grep -qxF 'export PYENV_ROOT='  ~/.bash_profile
if [ $? -ne 0 ]; then
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo 'export PATH="$PYENV_ROOT/shims:$PATH"' >> ~/.bash_profile
fi

npm install --global git-open

code --install-extension ms-vscode-remote.remote-ssh
