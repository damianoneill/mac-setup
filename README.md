# mac-setup

This solution will install homebrew and then use brew to install the dependencies. At various point's homebrew may ask you for your password.

It defaults to zsh and installs [oh my zsh](https://github.com/ohmyzsh/ohmyzsh) if not present.

[asdf](https://github.com/asdf-vm/asdf) is used as the version manager, it installs the following language plugins and some default versions for each language:

- Java
- Golang
- Node
- Python

Note at the end Virtualbox may fail, if it needs permissions granted for oracle before installing the software, it will provide the location of the change you require. Follow the instructions, then run the script again.

```sh
./install.sh
```
