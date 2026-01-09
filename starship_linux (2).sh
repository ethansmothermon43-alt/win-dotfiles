#!/bin/bash

# Starship Installation Script for Linux/macOS
# This script installs Starship prompt and configures zsh/bash

set -e

echo "🚀 Starting Starship installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo -e "${GREEN}Detected OS: ${MACHINE}${NC}"

# Detect shell
CURRENT_SHELL=$(basename "$SHELL")
echo -e "${GREEN}Detected shell: ${CURRENT_SHELL}${NC}"

# Check if shell is installed
if ! command -v "$CURRENT_SHELL" &> /dev/null; then
    echo -e "${RED}✗ ${CURRENT_SHELL} is not installed properly.${NC}"
    exit 1
fi

# Install Starship
echo -e "${YELLOW}📦 Installing Starship...${NC}"
if command -v starship &> /dev/null; then
    echo -e "${GREEN}✓ Starship is already installed${NC}"
else
    curl -sS https://starship.rs/install.sh | sh
fi

# Create config directory if it doesn't exist
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"

# Backup existing starship config if it exists
if [ -f "$CONFIG_DIR/starship.toml" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}⚠ Backing up existing starship.toml to starship.toml.backup_${TIMESTAMP}${NC}"
    cp "$CONFIG_DIR/starship.toml" "$CONFIG_DIR/starship.toml.backup_${TIMESTAMP}"
fi

# Copy starship config
echo -e "${YELLOW}📝 Creating Starship configuration...${NC}"
cat > "$CONFIG_DIR/starship.toml" << 'EOF'
# ~/.config/starship.toml

add_newline = false
command_timeout = 1000
format = """$os$username$hostname$kubernetes$directory$git_branch$git_status"""

# Drop ugly default prompt characters
[character]
success_symbol = ''
error_symbol = ''

# ---

[os]
format = '[$symbol](bold white) '   
disabled = false

[os.symbols]
Windows = ''
Arch = '󰣇'
Ubuntu = ''
Macos = '󰀵'

# ---

# Shows the username
[username]
style_user = 'white bold'
style_root = 'black bold'
format = '[$user]($style) '
disabled = false
show_always = true

# Shows the hostname
[hostname]
ssh_only = false
format = 'on [$hostname](bold yellow) '
disabled = false

# Shows current directory
[directory]
truncation_length = 1
truncation_symbol = '…/'
home_symbol = '󰋜 ~'
read_only_style = '197'
read_only = '  '
format = 'at [$path]($style)[$read_only]($read_only_style) '

# Shows current git branch
[git_branch]
symbol = ' '
format = 'via [$symbol$branch]($style)'
# truncation_length = 4
truncation_symbol = '…/'
style = 'bold green'

# Shows current git status
[git_status]
format = '[$all_status$ahead_behind]($style) '
style = 'bold green'
conflicted = '🏳'
up_to_date = ''
untracked = ' '
ahead = '⇡${count}'
diverged = '⇕⇡${ahead_count}⇣${behind_count}'
behind = '⇣${count}'
stashed = ' '
modified = ' '
staged = '[++\($count\)](green)'
renamed = '襁 '
deleted = ' '

# Shows kubernetes context and namespace
[kubernetes]
format = 'via [󱃾 $context\($namespace\)](bold purple) '
disabled = false

# ---

[vagrant]
disabled = true

[docker_context]
disabled = true

[helm]
disabled = true

[python]
disabled = true

[nodejs]
disabled = true

[ruby]
disabled = true

[terraform]
disabled = true
EOF

echo -e "${GREEN}✓ Starship configuration created${NC}"

# Create helper scripts directory
SCRIPTS_DIR="$HOME/.shell_scripts"
mkdir -p "$SCRIPTS_DIR"

# Create prompt.sh
echo -e "${YELLOW}📝 Creating prompt.sh...${NC}"
cat > "$SCRIPTS_DIR/prompt.sh" << 'EOF'
# Initialize Starship
eval "$(starship init $SHELL_NAME)"
EOF

echo -e "${GREEN}✓ prompt.sh created${NC}"

# Create kubectl.sh if needed
echo -e "${YELLOW}📝 Creating kubectl.sh...${NC}"
cat > "$SCRIPTS_DIR/kubectl.sh" << 'EOF'
# Kubectl Functions
# ---
#
alias k="kubectl"
alias h="helm"

kn() {
    if [ "$1" != "" ]; then
        kubectl config set-context --current --namespace=$1
        echo -e "\e[1;32m✓ Namespace set to $1\e[0m" 
    else
        echo -e "\e[1;31m✗ Error, please provide a valid Namespace\e[0m"
    fi
}

knd() {
    kubectl config set-context --current --namespace=default
    echo -e "\e[1;32m✓ Namespace set to Default\e[0m"
}

ku() {
    kubectl config unset current-context
    echo -e "\e[1;32m✓ unset kubernetes current-context\e[0m"
}
EOF

echo -e "${GREEN}✓ kubectl.sh created${NC}"

# Configure shell based on detected shell
if [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo -e "${YELLOW}⚠ Unknown shell: $CURRENT_SHELL, defaulting to .bashrc${NC}"
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
fi

# Backup shell RC if it exists
if [ -f "$SHELL_RC" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}⚠ Backing up existing $SHELL_RC to ${SHELL_RC}.backup_${TIMESTAMP}${NC}"
    cp "$SHELL_RC" "${SHELL_RC}.backup_${TIMESTAMP}"
fi

# Update shell RC
echo -e "${YELLOW}📝 Updating $SHELL_RC...${NC}"

# Check if starship is already configured
if grep -q "starship init" "$SHELL_RC" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Starship already configured in $SHELL_RC${NC}"
else
    # Add configuration to shell RC
    cat >> "$SHELL_RC" << EOF

# Starship Prompt Configuration
export SHELL_NAME="$SHELL_NAME"
source "\$HOME/.shell_scripts/prompt.sh"

# Kubectl helpers (optional - comment out if not needed)
source "\$HOME/.shell_scripts/kubectl.sh"
EOF
    echo -e "${GREEN}✓ $SHELL_RC updated${NC}"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart your terminal or run: source $SHELL_RC"
echo "  2. Make sure you have a Nerd Font installed for icons to display correctly"
echo "     Download from: https://www.nerdfonts.com/"
echo "     Recommended: FiraCode Nerd Font, CascadiaCode Nerd Font, or Hack Nerd Font"
echo "  3. Configure your terminal to use the Nerd Font"
echo ""
echo -e "${GREEN}Configuration files:${NC}"
echo "  • Starship config: ~/.config/starship.toml"
echo "  • Shell config: $SHELL_RC"
echo "  • Helper scripts: ~/.shell_scripts/"
echo ""
echo -e "${CYAN}To customize your prompt, edit: ~/.config/starship.toml${NC}"
echo ""