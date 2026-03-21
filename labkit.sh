#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

STAGE_DIR=".labkit-tmp"
DEFAULT_SOURCE="dallen4/labkit"

# Helper functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

info() {
    echo -e "${BLUE}$1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check dependencies
check_deps() {
    if ! command -v node &> /dev/null; then
        error "Node.js is required but not installed"
    fi

    if ! command -v npx &> /dev/null; then
        error "npx is required but not installed"
    fi
}

# Read .labkitrc using Node
read_config() {
    if [ ! -f ".labkitrc" ]; then
        return 1
    fi

    node -e "
        const fs = require('fs');
        const yaml = require('js-yaml');
        try {
            const config = yaml.load(fs.readFileSync('.labkitrc', 'utf8'));
            console.log(JSON.stringify(config));
        } catch (e) {
            process.exit(1);
        }
    " 2>/dev/null
}

# Write .labkitrc
write_config() {
    local source=$1
    shift
    local platforms=("$@")

    cat > .labkitrc << EOF
source: $source

platforms:
$(printf "  - %s\n" "${platforms[@]}")

skills: []
commands: []
rules: []
EOF

    success "Written .labkitrc"
}

# Stage directories with tiged
stage_directories() {
    local source=$1
    shift
    local platforms=("$@")

    info "Staging patterns from $source..."

    # Always fetch .claude for cross-compat skills
    npx tiged "$source/.claude" "$STAGE_DIR/.claude" --force &> /dev/null || true

    # Fetch platform-specific directories
    for platform in "${platforms[@]}"; do
        case $platform in
            cursor)
                npx tiged "$source/.cursor" "$STAGE_DIR/.cursor" --force &> /dev/null || true
                ;;
            windsurf)
                npx tiged "$source/.windsurf" "$STAGE_DIR/.windsurf" --force &> /dev/null || true
                ;;
            copilot)
                npx tiged "$source/.github" "$STAGE_DIR/.github" --force &> /dev/null || true
                ;;
        esac
    done

    # Fetch scripts
    npx tiged "$source/scripts" "$STAGE_DIR/scripts" --force &> /dev/null || true
}

# Copy patterns using shell globs
copy_patterns() {
    local config_json=$1

    # Parse config
    local source=$(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).source")
    local platforms=($(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).platforms.join(' ')"))
    local skills=($(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).skills.join(' ')"))
    local commands=($(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).commands.join(' ')"))
    local rules=($(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).rules.join(' ')"))

    # Copy skills
    for skill in "${skills[@]}"; do
        if [ -d "$STAGE_DIR/.claude/skills/$skill" ]; then
            mkdir -p ".claude/skills"
            cp -r "$STAGE_DIR/.claude/skills/$skill" ".claude/skills/"
            success ".claude/skills/$skill/"
        fi
    done

    # Copy commands per platform
    for platform in "${platforms[@]}"; do
        case $platform in
            claude)
                if [ ${#commands[@]} -gt 0 ]; then
                    mkdir -p ".claude/commands"
                    for cmd in "${commands[@]}"; do
                        if [ -f "$STAGE_DIR/.claude/commands/$cmd.md" ]; then
                            cp "$STAGE_DIR/.claude/commands/$cmd.md" ".claude/commands/"
                            success ".claude/commands/$cmd.md"
                        fi
                    done
                fi
                ;;
            cursor)
                if [ ${#commands[@]} -gt 0 ]; then
                    mkdir -p ".cursor/commands"
                    for cmd in "${commands[@]}"; do
                        if [ -f "$STAGE_DIR/.cursor/commands/$cmd.md" ]; then
                            cp "$STAGE_DIR/.cursor/commands/$cmd.md" ".cursor/commands/"
                            success ".cursor/commands/$cmd.md"
                        fi
                    done
                fi
                ;;
        esac
    done

    # Copy rules per platform
    for platform in "${platforms[@]}"; do
        case $platform in
            cursor)
                if [ ${#rules[@]} -gt 0 ]; then
                    mkdir -p ".cursor/rules"
                    for rule in "${rules[@]}"; do
                        if [ -f "$STAGE_DIR/.cursor/rules/$rule.mdc" ]; then
                            cp "$STAGE_DIR/.cursor/rules/$rule.mdc" ".cursor/rules/"
                            success ".cursor/rules/$rule.mdc"
                        fi
                    done
                fi
                ;;
            windsurf)
                if [ ${#rules[@]} -gt 0 ]; then
                    mkdir -p ".windsurf/rules"
                    for rule in "${rules[@]}"; do
                        if [ -f "$STAGE_DIR/.windsurf/rules/$rule.md" ]; then
                            cp "$STAGE_DIR/.windsurf/rules/$rule.md" ".windsurf/rules/"
                            success ".windsurf/rules/$rule.md"
                        fi
                    done
                fi
                ;;
            copilot)
                if [ -f "$STAGE_DIR/.github/copilot-instructions.md" ]; then
                    mkdir -p ".github"
                    cp "$STAGE_DIR/.github/copilot-instructions.md" ".github/"
                    success ".github/copilot-instructions.md"
                fi
                ;;
        esac
    done

    # Copy scripts
    if [ -d "$STAGE_DIR/scripts" ]; then
        mkdir -p "scripts"
        cp -r "$STAGE_DIR/scripts/"* "scripts/"
        success "scripts/"
    fi
}

# Cleanup staging directory
cleanup() {
    if [ -d "$STAGE_DIR" ]; then
        rm -rf "$STAGE_DIR"
    fi
}

# Interactive init
cmd_init() {
    clear
    echo "┌─────────────────────────────────────────┐"
    echo "│  labkit — build your own toolkit       │"
    echo "└─────────────────────────────────────────┘"
    echo

    # Check for existing config
    if [ -f ".labkitrc" ]; then
        echo -n "$(warn '.labkitrc already exists. Overwrite? [y/N]') "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info "Operation cancelled"
            exit 0
        fi
    fi

    # Source repo
    echo -n "Source repo? [dallen4/labkit]: "
    read -r source
    source=${source:-$DEFAULT_SOURCE}

    # Platforms (simple bash select menu)
    echo
    info "Select platforms (space-separated numbers, e.g., '1 2'):"
    echo "  1) Claude Code"
    echo "  2) Cursor"
    echo "  3) Windsurf"
    echo "  4) GitHub Copilot"
    echo -n "Your selection: "
    read -r platform_selection

    declare -a platforms
    for num in $platform_selection; do
        case $num in
            1) platforms+=("claude") ;;
            2) platforms+=("cursor") ;;
            3) platforms+=("windsurf") ;;
            4) platforms+=("copilot") ;;
        esac
    done

    if [ ${#platforms[@]} -eq 0 ]; then
        error "At least one platform must be selected"
    fi

    # Write basic config (user can edit for skills/commands/rules)
    write_config "$source" "${platforms[@]}"

    warn "Edit .labkitrc to add skills, commands, and rules, then run: ./labkit.sh sync"
}

# Sync from config
cmd_sync() {
    # Read config
    config_json=$(read_config)
    if [ $? -ne 0 ]; then
        error ".labkitrc not found. Run './labkit.sh init' first."
    fi

    source=$(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).source")
    platforms=($(echo "$config_json" | node -pe "JSON.parse(require('fs').readFileSync(0)).platforms.join(' ')"))

    info "Syncing from $source..."

    # Stage directories
    stage_directories "$source" "${platforms[@]}"

    # Copy patterns
    echo
    info "Installing patterns:"
    copy_patterns "$config_json"

    # Cleanup
    cleanup

    echo
    success "Done! Run 'scripts/hydrate.sh' to set up skill dependencies."
}

# Main
check_deps

case "${1:-}" in
    init)
        cmd_init
        ;;
    sync)
        cmd_sync
        ;;
    help|--help|-h)
        cat << EOF
labkit — reusable kit of agentic patterns for AI coding assistants

Usage:
  ./labkit.sh init    Interactive setup
  ./labkit.sh sync    Pull latest versions from .labkitrc
  ./labkit.sh help    Show this help

Examples:
  ./labkit.sh init              # Start interactive setup
  ./labkit.sh sync              # Update all patterns from source

Learn more: https://github.com/dallen4/labkit
EOF
        ;;
    *)
        error "Unknown command: ${1:-}. Try './labkit.sh help'"
        ;;
esac
