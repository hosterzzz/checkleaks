#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_green() {
    echo -e "${GREEN}$1${NC}"
}

echo_red() {
    echo -e "${RED}$1${NC}"
}

echo_yellow() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to detect OS and architecture
detect_platform() {
    # Detect OS
    case "$(uname -s)" in
        Linux*)     OS=linux;;
        Darwin*)    OS=darwin;;
        CYGWIN*)    OS=windows;;
        MINGW*)     OS=windows;;
        MSYS*)      OS=windows;;
        *)          echo_red "Unsupported operating system: $(uname -s)"; exit 1;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   ARCH=x64;;
        arm64|aarch64)  ARCH=arm64;;
        armv7l)         ARCH=armv7;;
        i386|i686)      ARCH=x32;;
        *)              echo_red "Unsupported architecture: $(uname -m)"; exit 1;;
    esac

    echo_yellow "Detected platform: $OS/$ARCH"
}

# Function to get latest gitleaks release
get_latest_gitleaks() {
    echo_yellow "Getting latest gitleaks release..."
    
    # Get latest version tag
    LATEST_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo_red "Failed to get latest version. Using fallback version v8.18.0"
        LATEST_VERSION="v8.18.0"
    fi
    
    echo_green "Latest version: $LATEST_VERSION"
    
    # Construct download URL based on platform - fix the naming convention
    if [ "$OS" = "windows" ]; then
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/${LATEST_VERSION}/gitleaks_${LATEST_VERSION#v}_windows_${ARCH}.zip"
        ARCHIVE_FILE="gitleaks.zip"
    else
        # Remove 'v' prefix from version for filename
        VERSION_NUM=${LATEST_VERSION#v}
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/${LATEST_VERSION}/gitleaks_${VERSION_NUM}_${OS}_${ARCH}.tar.gz"
        ARCHIVE_FILE="gitleaks.tar.gz"
    fi
    
    echo_yellow "Download URL: $DOWNLOAD_URL"
}

# Function to install gitleaks binary
install_gitleaks_binary() {
    echo_yellow "Downloading gitleaks..."
    
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    cd "$TEMP_DIR"
    
    # Download the archive
    if ! curl -sSfL "$DOWNLOAD_URL" -o "$ARCHIVE_FILE"; then
        echo_red "Failed to download gitleaks from $DOWNLOAD_URL"
        exit 1
    fi
    
    # Extract based on file type
    echo_yellow "Extracting gitleaks..."
    if [ "$OS" = "windows" ]; then
        if command -v unzip >/dev/null 2>&1; then
            unzip -q "$ARCHIVE_FILE"
        else
            echo_red "unzip command not found. Please install unzip."
            exit 1
        fi
        BINARY_NAME="gitleaks.exe"
    else
        if command -v tar >/dev/null 2>&1; then
            tar -xzf "$ARCHIVE_FILE"
        else
            echo_red "tar command not found. Please install tar."
            exit 1
        fi
        BINARY_NAME="gitleaks"
    fi
    
    # Make executable and install
    chmod +x "$BINARY_NAME"
    
    # Try to install to system location, fallback to user location
    if [ -w "/usr/local/bin" ] 2>/dev/null; then
        echo_yellow "Installing to /usr/local/bin..."
        mv "$BINARY_NAME" "/usr/local/bin/gitleaks"
    elif sudo -n true 2>/dev/null; then
        echo_yellow "Installing to /usr/local/bin (with sudo)..."
        sudo mv "$BINARY_NAME" "/usr/local/bin/gitleaks"
    else
        # Install to user local bin
        USER_BIN="$HOME/.local/bin"
        mkdir -p "$USER_BIN"
        echo_yellow "Installing to $USER_BIN..."
        mv "$BINARY_NAME" "$USER_BIN/gitleaks"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
            echo_yellow "Adding $USER_BIN to PATH..."
            
            # Add to bashrc
            if [ -f "$HOME/.bashrc" ] && ! grep -q "$USER_BIN" "$HOME/.bashrc"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            fi
            
            # Add to zshrc
            if [ -f "$HOME/.zshrc" ] && ! grep -q "$USER_BIN" "$HOME/.zshrc"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            fi
            
            echo_yellow "Please restart your shell or run: export PATH=\"$USER_BIN:\$PATH\""
        fi
    fi
    
    echo_green "✅ Gitleaks installed successfully!"
    
    # Test installation
    if command -v gitleaks >/dev/null 2>&1; then
        gitleaks version
    else
        echo_yellow "Gitleaks installed but not in current PATH. You may need to restart your shell."
    fi
}

# Function to install pre-commit and Gitleaks
install_dependencies() {
    echo_yellow "Installing dependencies..."
    
    # Detect platform first
    detect_platform
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y python3-pip curl
        pip3 install pre-commit
        
        # Get and install latest gitleaks
        get_latest_gitleaks
        install_gitleaks_binary
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install pre-commit gitleaks
        else
            echo_yellow "Homebrew not found. Installing manually..."
            
            # Install pre-commit via pip
            if command -v pip3 >/dev/null 2>&1; then
                pip3 install pre-commit
            elif command -v pip >/dev/null 2>&1; then
                pip install pre-commit
            else
                echo_red "Python pip not found. Please install Python first."
                exit 1
            fi
            
            # Install gitleaks manually
            get_latest_gitleaks
            install_gitleaks_binary
        fi
        
    elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
        # Install pre-commit
        if command -v pip >/dev/null 2>&1; then
            pip install pre-commit
        elif command -v pip3 >/dev/null 2>&1; then
            pip3 install pre-commit
        else
            echo_red "Python pip not found. Please install Python first."
            exit 1
        fi
        
        # Install gitleaks
        get_latest_gitleaks
        install_gitleaks_binary
        
    else
        echo_red "Unsupported OS: $OSTYPE"
        exit 1
    fi
    
    echo_green "Dependencies installed successfully."
}

# Function to configure pre-commit hook for Gitleaks
setup_pre_commit_hook() {
    echo_yellow "Configuring pre-commit for Gitleaks..."
    
    # Check if we're in a git repository
    ##if [ ! -d ".git" ]; then
    ##    echo_red "Error: Not in a git repository. Please run this script from the root of your git repository."
    ##    exit 1
    ##fi
    
    # Get the latest version for config
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v8.18.0")
    fi
    
    cat <<EOF > .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: $LATEST_VERSION
    hooks:
      - id: gitleaks
        name: gitleaks
        entry: gitleaks
        language: system
        pass_filenames: false
        args: ['detect', '--staged', '--verbose']
EOF

    # Install pre-commit hooks
    pre-commit install
    
    # Configure git hooks path and enable gitleaks
    git config --local core.hooksPath "$(pwd)/.git/hooks"
    git config --local hooks.gitleaks true
    
    echo_green "✅ Pre-commit hook configured successfully with git config."
    echo_green "✅ Gitleaks hook enabled by default."
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  install     Install dependencies and setup pre-commit hook (default)"
    echo "  enable      Enable gitleaks hook via git config"
    echo "  disable     Disable gitleaks hook via git config"
    echo "  status      Show current gitleaks hook status"
    echo "  help        Show this help message"
}

# Function to enable gitleaks hook
enable_gitleaks_hook() {
    git config --local hooks.gitleaks true
    echo_green "✅ Gitleaks hook enabled via git config"
}

# Function to disable gitleaks hook
disable_gitleaks_hook() {
    git config --local hooks.gitleaks false
    echo_yellow "⚠️  Gitleaks hook disabled via git config"
}

# Function to show gitleaks hook status
show_gitleaks_status() {
    if [ ! -d ".git" ]; then
        echo_red "Error: Not in a git repository."
        exit 1
    fi
    
    GITLEAKS_ENABLED=$(git config --local --get hooks.gitleaks 2>/dev/null || echo "not set")
    
    echo "📊 Gitleaks Hook Status:"
    echo "----------------------"
    
    if [ "$GITLEAKS_ENABLED" = "true" ]; then
        echo_green "Status: ENABLED"
    elif [ "$GITLEAKS_ENABLED" = "false" ]; then
        echo_yellow "Status: DISABLED"
    else
        echo_red "Status: NOT CONFIGURED"
    fi
    
    # Check if gitleaks binary exists
    if command -v gitleaks >/dev/null 2>&1; then
        echo_green "✅ Gitleaks binary: $(which gitleaks)"
        gitleaks version 2>/dev/null || echo_yellow "Warning: Could not get version"
    else
        echo_red "❌ Gitleaks binary not found"
    fi
}

# Main script logic
case "${1:-install}" in
    "install")
        install_dependencies
        setup_pre_commit_hook
        echo_green "🎉 Setup completed! Use '$0 status' to check configuration."
        ;;
    "enable")
        enable_gitleaks_hook
        ;;
    "disable")
        disable_gitleaks_hook
        ;;
    "status")
        show_gitleaks_status
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo_red "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac