# mac-setup

This solution will install homebrew and then use brew to install the dependencies. At various point's homebrew may ask you for your password.

It defaults to zsh and installs [oh my zsh](https://github.com/ohmyzsh/ohmyzsh) if not present.

[asdf](https://github.com/asdf-vm/asdf) is used as the version manager, it installs the following language plugins and some default versions for each language:

- Java
- Golang
- Node
- Python

[Alacritty](https://github.com/alacritty/alacritty) is installed rather than iterm. Over the years the performance of iterm has diminished, for those with a OpenGL capable graphics card, Alacritty can leverage this to provide GPU based acceleration. This make Alacritty perform significantly faster than other terminal emulators. This performance comes at a cost, it does not provide any window multiplexing, if you require this function you should use [tmux](https://github.com/tmux/tmux). [This article](https://www.barbarianmeetscoding.com/blog/jaimes-guide-to-tmux-the-most-awesome-tool-you-didnt-know-you-needed) provides a great overview of tmux's functions.

Note at the end Virtualbox may fail, if it needs permissions granted for oracle before installing the software, it will provide the location of the change you require. Follow the instructions, then run the script again.

```sh
./install.sh
```
