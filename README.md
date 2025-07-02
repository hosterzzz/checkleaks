# Gitleaks Pre-commit Hook Setup

Automatically install and configure [Gitleaks](https://github.com/gitleaks/gitleaks) as a pre-commit hook to detect secrets and sensitive information in your Git repositories.

## Features

✅ **Cross-platform support** (Linux, macOS, Windows)  
✅ **Automatic dependency installation** (pre-commit, gitleaks)  
✅ **Latest version detection** from GitHub releases  
✅ **Easy enable/disable** via git config  
✅ **Status monitoring** and health checks  
✅ **One-line installation** via curl  

## Quick Installation

### From any Git repository:

```bash
# Navigate to your git repository
cd /path/to/your/git/repo

# Install via curl (one-liner)
curl -sSL https://raw.githubusercontent.com/yourusername/checkleaks/main/setup-precommit-gitleaks-gitconfig.sh | bash
```

### Manual installation:

```bash
# Clone or download the script
wget https://raw.githubusercontent.com/yourusername/checkleaks/main/setup-precommit-gitleaks-gitconfig.sh
chmod +x setup-precommit-gitleaks-gitconfig.sh

# Run from within a git repository
cd your-git-repo
./setup-precommit-gitleaks-gitconfig.sh
```

## Usage

```bash
./setup-precommit-gitleaks-gitconfig.sh [OPTION]
```

### Available Options:

| Option | Description |
|--------|-------------|
| `install` | Install dependencies and setup pre-commit hook (default) |
| `enable` | Enable gitleaks hook via git config |
| `disable` | Disable gitleaks hook via git config |
| `status` | Show current gitleaks hook status |
| `help` | Show help message |

### Examples:

```bash
# Full installation (default)
./setup-precommit-gitleaks-gitconfig.sh

# Check status
./setup-precommit-gitleaks-gitconfig.sh status

# Temporarily disable
./setup-precommit-gitleaks-gitconfig.sh disable

# Re-enable
./setup-precommit-gitleaks-gitconfig.sh enable
```

## What This Script Does

### 1. **Dependency Installation**
- Detects your platform (OS and architecture)
- Installs Python pip and pre-commit
- Downloads and installs the latest gitleaks binary
- Automatically handles different package managers (apt, brew, pip)

### 2. **Pre-commit Configuration**
- Creates `.pre-commit-config.yaml` with gitleaks hook
- Installs pre-commit hooks in your repository
- Configures git to use the hooks

### 3. **Git Configuration**
- Sets up `hooks.gitleaks` config for easy enable/disable
- Configures proper hooks path
- Enables gitleaks scanning by default

## Installation Locations

The script intelligently chooses installation locations:

1. **System-wide** (`/usr/local/bin`) - if writable or sudo available
2. **User local** (`~/.local/bin`) - fallback option
3. **PATH updates** - automatically updates shell configs

## Platform Support

| Platform | Status | Package Manager |
|----------|--------|-----------------|
| Linux (Ubuntu/Debian) | ✅ | apt-get |
| macOS | ✅ | homebrew (preferred) or manual |
| Windows (WSL/Cygwin) | ✅ | manual installation |

### Architecture Support:
- x86_64 / amd64
- ARM64 / aarch64
- ARMv7
- i386 / i686

## Requirements

### Minimal Requirements:
- Git repository (script must run from within a git repo)
- `curl` for downloading
- `tar` or `unzip` for extraction

### Auto-installed Dependencies:
- Python 3 and pip
- pre-commit package
- gitleaks binary

## Configuration Files Created

### `.pre-commit-config.yaml`
```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0  # Latest version auto-detected
    hooks:
      - id: gitleaks
        name: gitleaks
        entry: gitleaks
        language: system
        pass_filenames: false
        args: ['detect', '--staged', '--verbose']
```

### Git Configuration
```bash
# Local repository settings
git config --local core.hooksPath "$(pwd)/.git/hooks"
git config --local hooks.gitleaks true  # Enable/disable flag
```

## Usage in Development Workflow

Once installed, gitleaks will automatically run:

1. **On every commit** - scans staged files for secrets
2. **Before push** - prevents accidental secret commits
3. **With verbose output** - shows what's being scanned

### Example commit flow:
```bash
git add .
git commit -m "Add new feature"
# Gitleaks automatically scans staged files
# Commit is blocked if secrets are found
```

### Bypass (emergency only):
```bash
# Temporarily skip all pre-commit hooks
git commit --no-verify -m "Emergency fix"

# Or disable just gitleaks
./setup-precommit-gitleaks-gitconfig.sh disable
git commit -m "Normal commit"
./setup-precommit-gitleaks-gitconfig.sh enable
```

## Troubleshooting

### Common Issues:

**"Not in a git repository" error:**
```bash
# Make sure you're in a git repo
git init  # or navigate to existing repo
cd /path/to/your/git/repo
```

**"gitleaks not found" after installation:**
```bash
# Restart your shell or update PATH
export PATH="$HOME/.local/bin:$PATH"
# Or restart terminal
```

**Permission denied during installation:**
```bash
# Script will automatically try sudo or fallback to user install
# For manual override:
sudo ./setup-precommit-gitleaks-gitconfig.sh
```

**Pre-commit hook not running:**
```bash
# Check status
./setup-precommit-gitleaks-gitconfig.sh status

# Reinstall hooks
pre-commit install --install-hooks
```

### Debug Commands:
```bash
# Check gitleaks installation
which gitleaks
gitleaks version

# Check pre-commit setup
pre-commit --version
pre-commit run --all-files gitleaks

# Check git config
git config --local --list | grep hooks
```

## Advanced Configuration

### Custom Gitleaks Rules:
Create `.gitleaks.toml` in your repository root:

```toml
[extend]
# Extend default config
useDefault = true

[[rules]]
description = "Custom API Key Pattern"
regex = '''my-api-[0-9a-zA-Z]{32}'''
tags = ["custom", "api-key"]
```

### Multiple Hook Configuration:
Add more hooks to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
```

## Security Best Practices

1. **Run on all commits** - Keep gitleaks enabled always
2. **Scan existing history** - Run `gitleaks detect` on old repositories
3. **Update regularly** - Re-run installer to get latest versions
4. **Custom rules** - Add organization-specific secret patterns
5. **CI/CD integration** - Use gitleaks in your build pipeline

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test on multiple platforms
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Related Tools

- [Gitleaks](https://github.com/gitleaks/gitleaks) - The secret detection tool
- [Pre-commit](https://pre-commit.com/) - Git hook framework
- [TruffleHog](https://github.com/trufflesecurity/trufflehog) - Alternative secret scanner
- [GitGuardian](https://www.gitguardian.com/) - Commercial secret detection

## Support

- 📖 [Gitleaks Documentation](https://github.com/gitleaks/gitleaks#readme)
- 🐛 [Report Issues](https://github.com/yourusername/checkleaks/issues)
- 💬 [Discussions](https://github.com/yourusername/checkleaks/discussions)

---

**⚠️ Important:** Always review what secrets are detected and ensure your `.gitleaks.toml` configuration matches your security requirements.

