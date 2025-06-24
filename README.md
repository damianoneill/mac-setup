# mac-setup

This solution will install homebrew and then use brew to install the dependencies. At various point's homebrew may ask you for your password.

Use latest version of bash on homebrew, will set this up as the default shell, and install some common tools and languages.

[asdf](https://github.com/asdf-vm/asdf) is used as the version manager, it installs the following language plugins and some default versions for each language:

- Java
- Golang
- Node
- Python

Note at the end Virtualbox may fail, if it needs permissions granted for oracle before installing the software, it will provide the location of the change you require. Follow the instructions, then run the script again.

```sh
./install.sh
```
