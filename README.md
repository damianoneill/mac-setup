# mac-setup

## Homebrew
The solution is dependent on homebrew

````
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
$ brew tap caskroom/cask
````

## Ansible
Install Ansbile

````
$ brew install ansible
````

## Ansible Galaxy
Use Galaxy to install the dependent roles

````
$ ansible-galaxy install -r requirements.yml
````

## Run the installation
Then to run the local installation. 

````
ansible-playbook master.yml --ask-become-pass
````
