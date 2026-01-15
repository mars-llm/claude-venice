#!/usr/bin/env bash
#
# Venice + Claude Code Installer
# Routes Claude Code through Venice.ai via claude-code-router
#
# Usage:
#   ./install.sh
#   VENICE_API_KEY=xxx ./install.sh
#   ./install.sh --api-key YOUR_KEY

set -e

VERSION="3.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Defaults
VENICE_API_KEY="${VENICE_API_KEY:-}"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.claude-code-router"

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
    ┌─┬─┬─┐
    │ │ │ │    ╭─────────────╮
   ┌┴─┴─┴─┴┐   │  mars-llm   │
   │ ◣   ◢ │   ╰─────────────╯
   │  ───  │  Venice Installer
   └───────┘
BANNER
    echo -e "${RESET}"
    echo -e "  ${DIM}v${VERSION}${RESET}"
    echo ""
}

log_info() { echo -e "${CYAN}→${RESET} $1"; }
log_success() { echo -e "${GREEN}✓${RESET} $1"; }
log_warn() { echo -e "${YELLOW}!${RESET} $1"; }
log_error() { echo -e "${RED}✗${RESET} $1" >&2; }

die() { log_error "$1"; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --api-key|-k) VENICE_API_KEY="$2"; shift 2 ;;
        --install-dir) INSTALL_DIR="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --api-key, -k KEY    Venice API key"
            echo "  --install-dir DIR    Install directory (default: ~/.local/bin)"
            echo "  --help, -h           Show this help"
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
done

show_banner

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v node &>/dev/null; then
    die "Node.js is required. Install from https://nodejs.org"
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [[ "$NODE_VERSION" -lt 18 ]]; then
    die "Node.js 18+ required (found: $(node -v))"
fi
log_success "Node.js $(node -v)"

if ! command -v jq &>/dev/null; then
    die "jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"
fi
log_success "jq $(jq --version)"

if ! command -v curl &>/dev/null; then
    die "curl is required"
fi
log_success "curl available"

# Get API key
if [[ -z "$VENICE_API_KEY" ]]; then
    echo ""
    echo -e "${BOLD}Venice API Key${RESET}"
    echo -e "${DIM}Get your key at: https://venice.ai/settings/api?ref=JiSk4J${RESET}"
    echo ""
    read -p "Enter your Venice API key: " VENICE_API_KEY
    echo ""
fi

if [[ -z "$VENICE_API_KEY" ]]; then
    die "API key is required"
fi

# Validate API key
log_info "Validating API key..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://api.venice.ai/api/v1/models" \
    -H "Authorization: Bearer $VENICE_API_KEY" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" != "200" ]]; then
    die "Invalid API key (HTTP $HTTP_CODE). Check your key at https://venice.ai/settings/api?ref=JiSk4J"
fi
log_success "API key valid"

# Create directories
log_info "Creating directories..."
mkdir -p "$CONFIG_DIR/logs"
mkdir -p "$INSTALL_DIR"
mkdir -p "$HOME/venice-output"
log_success "Directories created"

# Install claude-code-router
log_info "Installing claude-code-router..."
if command -v ccr &>/dev/null; then
    log_success "claude-code-router already installed"
else
    npm install -g claude-code-router || die "Failed to install claude-code-router"
    log_success "claude-code-router installed"
fi

# Create router configuration for Venice
log_info "Creating router configuration..."
cat > "$CONFIG_DIR/config-router.json" << EOF
{
  "server": {
    "port": 3456,
    "host": "127.0.0.1"
  },
  "routing": {
    "rules": {
      "default": { "provider": "venice", "model": "claude-opus-45" },
      "background": { "provider": "venice", "model": "claude-opus-45" },
      "thinking": { "provider": "venice", "model": "claude-opus-45" },
      "longcontext": { "provider": "venice", "model": "claude-opus-45" }
    },
    "defaultProvider": "venice",
    "providers": {
      "venice": {
        "type": "openai",
        "endpoint": "https://api.venice.ai/api/v1/chat/completions",
        "authentication": {
          "type": "bearer",
          "credentials": { "apiKey": "$VENICE_API_KEY" }
        },
        "settings": {
          "models": [
            "claude-opus-45",
            "deepseek-r1-671b",
            "qwen-2.5-coder-32b",
            "qwen3-235b",
            "llama-3.3-70b"
          ],
          "defaultModel": "claude-opus-45"
        }
      }
    }
  },
  "debug": {
    "enabled": false,
    "logLevel": "warn",
    "logDir": "~/.claude-code-router/logs"
  }
}
EOF
log_success "Router config: $CONFIG_DIR/config-router.json"

# Get script directory (for local installs)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Install CLI tools
log_info "Installing CLI tools..."

install_script() {
    local name="$1"
    if [[ ! -f "$SCRIPT_DIR/scripts/$name" ]]; then
        die "Script not found: $SCRIPT_DIR/scripts/$name (did you clone the repo?)"
    fi
    cp "$SCRIPT_DIR/scripts/$name" "$INSTALL_DIR/$name"
    chmod +x "$INSTALL_DIR/$name"
    log_success "Installed $name"
}

install_script "venice-model"
install_script "venice-ask"
install_script "venice-generate"

# Create launcher script
log_info "Creating code-venice launcher..."
cat > "$INSTALL_DIR/code-venice" << 'LAUNCHER'
#!/usr/bin/env bash
# code-venice: Launch Claude Code with Venice.ai backend
set -e

VERSION="3.0.0"
CONFIG_DIR="$HOME/.claude-code-router"
LOG_FILE="$CONFIG_DIR/logs/router.log"

# Colors
if [[ -t 1 ]]; then
    BOLD='\033[1m' DIM='\033[2m' CYAN='\033[0;36m' GREEN='\033[0;32m' RED='\033[0;31m' RESET='\033[0m'
else
    BOLD='' DIM='' CYAN='' GREEN='' RED='' RESET=''
fi

show_mars() {
    echo -e "\033[0;36m"
    cat << 'MARS'
    ┌─┬─┬─┐
    │ │ │ │    ╭─────────────╮
   ┌┴─┴─┴─┴┐   │  mars-llm   │
   │ ◣   ◢ │   ╰─────────────╯
   │  ───  │  code-venice
   └───────┘
MARS
    echo -e "\033[0m"
    echo "  version: $VERSION"
}

show_help() {
    echo "code-venice: Launch Claude Code with Venice.ai backend"
    echo ""
    echo "Usage: code-venice [options] [claude-args...]"
    echo ""
    echo "Options:"
    echo "  --mars           Show mars-llm banner"
    echo "  --help, -h       Show this help"
    echo ""
    echo "Inside Claude Code:"
    echo "  venice-ask -m deepseek-r1-671b \"question\"  Query specific model"
    echo "  venice-ask \"question\"                      Query uncensored model"
    echo "  venice-generate video \"prompt\"             Generate media"
}

# Parse arguments
ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mars) show_mars; exit 0 ;;
        --help|-h) show_help; exit 0 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

# Start router if not running
if ! curl -s http://127.0.0.1:3456/health >/dev/null 2>&1; then
    echo "Starting claude-code-router..."
    mkdir -p "$(dirname "$LOG_FILE")"
    ccr start >> "$LOG_FILE" 2>&1 &

    for i in {1..10}; do
        if curl -s http://127.0.0.1:3456/health >/dev/null 2>&1; then
            echo -e "${GREEN}✓${RESET} Router ready"
            break
        fi
        sleep 0.5
    done

    if ! curl -s http://127.0.0.1:3456/health >/dev/null 2>&1; then
        echo -e "${RED}Error:${RESET} Router failed to start. Check $LOG_FILE" >&2
        exit 1
    fi
fi

echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│  Venice.ai Backend                                          │"
echo "│                                                             │"
echo "│  Query models: venice-ask -m <model> \"question\"             │"
echo "│  Generate:     venice-generate video/image/audio            │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# Export routing env vars and launch claude
export ANTHROPIC_BASE_URL="http://127.0.0.1:3456"
export ANTHROPIC_AUTH_TOKEN="venice-router"

# Use cc-mirror instance if available, otherwise vanilla claude
if command -v venice &>/dev/null; then
    exec venice "${ARGS[@]}"
elif command -v claude &>/dev/null; then
    exec claude "${ARGS[@]}"
else
    echo -e "${RED}Error:${RESET} Claude Code not found. Install from https://claude.ai/download" >&2
    exit 1
fi
LAUNCHER
chmod +x "$INSTALL_DIR/code-venice"
log_success "Created code-venice launcher"

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    log_warn "$INSTALL_DIR is not in your PATH"

    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        read -p "Add to PATH in $SHELL_RC? (Y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "" >> "$SHELL_RC"
            echo "# Venice + Claude Code" >> "$SHELL_RC"
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
            log_success "Added PATH to $SHELL_RC"
        fi
    fi
fi

# Done!
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo ""
echo -e "${BOLD}Quick Start:${RESET}"
echo ""
echo "  1. Open a new terminal (or: source ~/.zshrc)"
echo ""
echo "  2. Launch Claude Code with Venice:"
echo -e "     ${CYAN}code-venice${RESET}"
echo ""
echo -e "${BOLD}Commands (inside Claude Code):${RESET}"
echo ""
echo -e "  ${CYAN}venice-ask \"question\"${RESET}                Query uncensored model"
echo -e "  ${CYAN}venice-ask -m deepseek-r1-671b \"q\"${RESET}   Query specific model"
echo -e "  ${CYAN}venice-generate image \"...\"${RESET}          Generate images"
echo -e "  ${CYAN}venice-generate video \"...\"${RESET}          Generate videos"
echo ""
