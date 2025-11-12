#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}${NC} ${1}"
}

print_info() {
    echo -e "${YELLOW}?${NC} ${1}"
}

print_error() {
    echo -e "${RED}${NC} ${1}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Installation tracking
INSTALLED=()
SKIPPED=()

track_install() {
    INSTALLED+=("$1")
}

track_skip() {
    SKIPPED+=("$1")
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

print_header "Bootstrap-My-Mac"
echo ""

# 2. Install Homebrew
print_header "Checking Homebrew"
if ! command_exists brew; then
    print_info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    track_install "Homebrew"
else
    print_success "Homebrew already installed"
    print_info "Updating Homebrew"
    brew update
    track_skip "Homebrew"
fi
echo ""
#
# 3. Setup directory structure
print_header "Setting up directories"
mkdir -p ~/.config/zsh
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/nvim
mkdir -p ~/.config/homebrew
print_success "Directories created"
echo ""

# 4. Install packages via Homebrew
print_header "Installing packages from Brewfile"

cp "${SCRIPT_DIR}/Brewfile" ~/.config/homebrew
cd ~/.config/homebrew

# Install packages using Brewfile
if brew bundle check &>/dev/null; then
    print_success "All packages already installed"
    track_skip "Homebrew packages"
else
    print_info "Installing packages with brew bundle"
    brew bundle install
    track_install "Homebrew packages"
fi

echo ""

# 5. Setup layered zsh configuration
print_header "Setting up zsh configuration"

# Create ~/.zshenv
cp "${SCRIPT_DIR}/zshenv" ~/.zshenv
print_success "Created ~/.zshenv"

# Create ~/.config/zsh/.zshrc that sources main and local configs
cp "${SCRIPT_DIR}/.zshrc" ~/.config/zsh/.zshrc
print_success "Created ~/.config/zsh/.zshrc"

# Create empty local zshrc if it doesn't exist
if [ ! -f ~/.config/zsh/zshrc ]; then
    cp "${SCRIPT_DIR}/zshrc" ~/.config/zsh/zshrc
    print_success "Created ~/.config/zsh/zshrc (local customizations)"
else
    print_success "Local ~/.config/zsh/zshrc already exists"
fi
echo ""

# 6. Setup layered alacritty configuration
print_header "Setting up alacritty configuration"

# Create ~/.config/alacritty/alacritty.toml that imports main config
cp "${SCRIPT_DIR}/alacritty.toml" ~/.config/alacritty/alacritty.toml
print_success "Created ~/.config/alacritty/alacritty.toml"
echo ""

# 7. Setup layered starship configuration
print_header "Setting up starship configuration"

# Copy starship config template with local customization area
cp "${SCRIPT_DIR}/starship.toml" ~/.config/starship.toml
print_success "Created ~/.config/starship.toml"
echo ""

exit

# 8. Setup LazyVim
print_header "Setting up LazyVim"

if [ -d ~/.config/nvim ]; then
    if [ ! -f ~/.config/nvim/init.lua ]; then
        # Backup existing nvim config if not empty and not a git repo
        if [ "$(ls -A ~/.config/nvim)" ]; then
            print_info "Backing up existing nvim config to ~/.config/nvim.backup"
            mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)
            mkdir -p ~/.config/nvim
        fi
    else
        print_success "LazyVim already installed"
        track_skip "LazyVim"
    fi
fi

if [ ! -f ~/.config/nvim/init.lua ]; then
    print_info "Installing LazyVim starter"
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
    track_install "LazyVim"
fi
echo ""

# 9. Setup asdf
print_header "Setting up asdf"

# Source asdf
ASDF_DIR="~/.asdf"
source "~/.asdf/asdf.sh"

if [ -n "$ASDF_DIR" ]; then
    print_success "asdf loaded from $ASDF_DIR"

    # Check for local tool-versions
    if [ -f ~/.tool-versions ]; then
        print_info "Installing tools from ~/.tool-versions"

        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            # Extract plugin name (first word)
            plugin=$(echo "$line" | awk '{print $1}')

            # Add plugin if not already added
            if ! asdf plugin list | grep -q "^${plugin}$"; then
                print_info "Adding asdf plugin: $plugin"
                asdf plugin add "$plugin"
                track_install "asdf plugin: $plugin"
            else
                track_skip "asdf plugin: $plugin"
            fi
        done < ~/.tool-versions

        # Install all tools
        print_info "Installing tools defined in tool-versions"
        cd
        asdf install
        cd - > /dev/null
        track_install "asdf tools from tool-versions"
    else
        print_info "No ~/.tool-versions found"
        print_info "Create this file to auto-install language runtimes via asdf"
    fi
else
    print_error "Could not locate asdf installation"
fi
echo ""

# 10. Print summary
print_header "Installation Summary"
echo ""

if [ ${#INSTALLED[@]} -gt 0 ]; then
    echo -e "${GREEN}Installed:${NC}"
    for item in "${INSTALLED[@]}"; do
        echo "  " $item"
    done
    echo ""
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo -e "${YELLOW}Already installed (skipped):${NC}"
    for item in "${SKIPPED[@]}"; do
        echo "  " $item"
    done
    echo ""
fi

print_header "Next Steps"
echo ""
print_info "1. Restart your terminal or run: source ~/.zshenv"
print_info "2. Add local customizations to:"
echo "     " ~/.config/zsh/zshrc (zsh)"
echo "     " ~/.config/alacritty/alacritty.toml (alacritty)"
echo "     " ~/.config/starship.toml (starship)"
echo "     " ~/.config/bootstrap-my-mac/tool-versions (asdf)"
echo ""
print_success "Bootstrap complete!"
