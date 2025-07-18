# Mac Setup Script

A comprehensive macOS development environment setup script that installs and configures essential tools, languages, and applications for software development.

> If running zscaler, disable Internet Security!

## Prerequisites

- **macOS** (Apple Silicon recommended - M1/M2/M3)
- **Xcode Command Line Tools** - Required for Git and compilation tools

  ```bash
  xcode-select --install
  ```

## Quick Start

1. Clone this repository into a projects directory (e.g. ~/projects/github.com/damianoneill/):

   ```bash
   mkdir -p ~/projects/github.com/damianoneill
   git clone git@github.com:damianoneill/mac-setup.git
   cd mac-setup
   ```

2. Make the script executable and run it:

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Restart your terminal** after installation to load all new configurations

## Post-Installation Steps

### 1. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Add SSH Key to GitHub/GitLab

Your new SSH key will be displayed at the end of installation. Copy the public key and add it to your Git hosting service:

```bash
cat ~/.ssh/id_ed25519.pub
```

### 3. Install Docker Desktop

Docker Desktop must be installed manually from [docker.com](https://www.docker.com/products/docker-desktop/) as it requires GUI installation.

## Key Features

- **Idempotent**: Safe to run multiple times
- **Apple Silicon Optimised**: Uses `/opt/homebrew` paths
- **Modern Defaults**: Replaces traditional Unix tools with improved alternatives
- **Development Ready**: Includes multiple language runtimes and package managers
- **VS Code Integration**: Pre-installs essential extensions

## Customisation

### Adding More Tools

Edit the arrays in `install.sh`:

```bash
declare -a productivity=(
  # Add your tools here
)
```

### Language Versions

The script installs the latest versions. To pin specific versions:

```bash
asdf install python 3.11.0
asdf global python 3.11.0
```

### VS Code Extensions

Add extensions to the `vscodeExts` array in the script.

## Troubleshooting

### Permission Issues

Some Homebrew installations may require your password. This is normal for system-level changes.

### Shell Changes

If your shell doesn't change automatically:

```bash
chsh -s $(which zsh)
```

### VS Code CLI

If `code` command isn't available, open VS Code and run "Shell Command: Install 'code' command in PATH" from the Command Palette.

### Tool Not Found

After installation, restart your terminal or source your shell configuration:

```bash
source ~/.zshrc
```

## Updating Everything

The script installs `topgrade` which can update all your tools:

```bash
topgrade
```

## File Structure

```
.
├── README.md          # This file
└── install.sh         # Main installation script
```

## Requirements

- macOS 10.15+ (Catalina or later)
- Administrator access (for some system changes)
- Internet connection
- ~2GB free disk space

---

**Note**: This script is designed for fresh macOS installations or systems where you want a comprehensive development setup. Review the script before running if you have existing configurations you want to preserve.
