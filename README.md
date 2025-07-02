##Pre-commit hook using gitleaks

Usage: ./setup-precommit-gitleaks-gitconfig.sh [OPTION]
Options:
  install     Install dependencies and setup pre-commit hook (default)
  enable      Enable gitleaks hook via git config
  disable     Disable gitleaks hook via git config
  status      Show current gitleaks hook status
  help        Show this help message

#For install you can run:

curl -sSL https://raw.githubusercontent.com/hosterzzz/checkleaks/refs/heads/main/setup-precommit-gitleaks-gitconfig.sh | bash

