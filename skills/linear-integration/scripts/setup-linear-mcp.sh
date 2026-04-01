#!/bin/bash

# Linear MCP Setup Script for VS Code
# This script automates the setup process for Linear MCP integration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "This script should be run from within a git repository"
        exit 1
    fi
    log_success "Running in git repository"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    log_success "Node.js found: $(node --version)"
    
    # Check npm/npx
    if ! command -v npx &> /dev/null; then
        log_error "npx is not available. Please install npm/npx first."
        exit 1
    fi
    log_success "npx found: $(npx --version)"
    
    # Check if VS Code is installed (optional check)
    if command -v code &> /dev/null; then
        log_success "VS Code found: $(code --version | head -n1)"
    else
        log_warning "VS Code CLI not found. Make sure VS Code is installed."
    fi
}

# Test Linear MCP server availability
test_mcp_server() {
    log_info "Testing Linear MCP server availability..."
    
    if timeout 10s npx -y linear-mcp-server --help > /dev/null 2>&1; then
        log_success "Linear MCP server is available"
    else
        log_error "Linear MCP server is not available or timed out"
        log_info "This might be normal - the server will be installed when needed"
    fi
}

# Get Linear API key from user
get_api_key() {
    echo
    log_info "Linear API Key Setup"
    echo "To get your Linear API key:"
    echo "1. Go to Linear → Settings → API → Personal API keys"
    echo "2. Click 'Create new API key'"
    echo "3. Give it a name (e.g., 'VS Code MCP Integration')"
    echo "4. Copy the generated key (starts with 'lin_api_')"
    echo
    
    while true; do
        read -s -p "Enter your Linear API key: " api_key
        echo
        
        if [[ -z "$api_key" ]]; then
            log_error "API key cannot be empty"
            continue
        fi
        
        if [[ ! "$api_key" =~ ^lin_api_ ]]; then
            log_warning "API key should start with 'lin_api_'. Are you sure this is correct?"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        
        break
    done
    
    LINEAR_API_KEY="$api_key"
}

# Set environment variable
set_environment_variable() {
    log_info "Setting up environment variable..."
    
    # Detect shell
    if [[ -n "$ZSH_VERSION" ]]; then
        SHELL_RC="$HOME/.zshrc"
        SHELL_NAME="zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_RC="$HOME/.bash_profile"
        else
            SHELL_RC="$HOME/.bashrc"
        fi
        SHELL_NAME="bash"
    else
        SHELL_RC="$HOME/.profile"
        SHELL_NAME="shell"
    fi
    
    log_info "Detected $SHELL_NAME shell, using $SHELL_RC"
    
    # Check if already exists
    if grep -q "LINEAR_API_KEY" "$SHELL_RC" 2>/dev/null; then
        log_warning "LINEAR_API_KEY already exists in $SHELL_RC"
        read -p "Replace existing key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove existing line
            sed -i.bak '/export LINEAR_API_KEY/d' "$SHELL_RC"
            log_info "Removed existing LINEAR_API_KEY"
        else
            log_info "Keeping existing LINEAR_API_KEY"
            return
        fi
    fi
    
    # Add new environment variable
    echo "export LINEAR_API_KEY=\"$LINEAR_API_KEY\"" >> "$SHELL_RC"
    log_success "Added LINEAR_API_KEY to $SHELL_RC"
    
    # Export for current session
    export LINEAR_API_KEY="$LINEAR_API_KEY"
    log_success "LINEAR_API_KEY set for current session"
}

# Create .vscode directory and mcp.json
create_mcp_config() {
    log_info "Creating VS Code MCP configuration..."
    
    # Create .vscode directory if it doesn't exist
    if [[ ! -d ".vscode" ]]; then
        mkdir .vscode
        log_success "Created .vscode directory"
    fi
    
    # Check if mcp.json already exists
    if [[ -f ".vscode/mcp.json" ]]; then
        log_warning "mcp.json already exists"
        read -p "Replace existing configuration? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing mcp.json"
            return
        fi
    fi
    
    # Create mcp.json
    cat > .vscode/mcp.json << 'EOF'
{
  "servers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "linear-mcp-server"],
      "env": {
        "LINEAR_API_KEY": "${env:LINEAR_API_KEY}"
      }
    }
  }
}
EOF
    
    log_success "Created .vscode/mcp.json"
}

# Test the configuration
test_configuration() {
    log_info "Testing configuration..."
    
    # Check if environment variable is set
    if [[ -z "$LINEAR_API_KEY" ]]; then
        log_error "LINEAR_API_KEY is not set in current session"
        return 1
    fi
    log_success "LINEAR_API_KEY is set in current session"
    
    # Check if mcp.json exists and is valid JSON
    if [[ ! -f ".vscode/mcp.json" ]]; then
        log_error ".vscode/mcp.json does not exist"
        return 1
    fi
    
    # Validate JSON syntax
    if ! python3 -m json.tool .vscode/mcp.json > /dev/null 2>&1; then
        if ! node -e "JSON.parse(require('fs').readFileSync('.vscode/mcp.json', 'utf8'))" 2>/dev/null; then
            log_error ".vscode/mcp.json contains invalid JSON"
            return 1
        fi
    fi
    log_success ".vscode/mcp.json is valid JSON"
    
    # Test Linear API access (optional)
    log_info "Testing Linear API access..."
    if command -v curl &> /dev/null; then
        if curl -s -H "Authorization: Bearer $LINEAR_API_KEY" \
           -H "Content-Type: application/json" \
           -d '{"query":"{ viewer { name } }"}' \
           https://api.linear.app/graphql | grep -q '"data"'; then
            log_success "Linear API access confirmed"
        else
            log_warning "Could not verify Linear API access. Check your API key."
        fi
    else
        log_warning "curl not found, skipping Linear API test"
    fi
}

# Main setup function
main() {
    echo "🚀 Linear MCP Setup Script for VS Code"
    echo "======================================"
    echo
    
    check_git_repo
    check_prerequisites
    test_mcp_server
    get_api_key
    set_environment_variable
    create_mcp_config
    
    echo
    log_info "Testing setup..."
    if test_configuration; then
        echo
        log_success "🎉 Linear MCP setup completed successfully!"
        echo
        echo "Next steps:"
        echo "1. Restart your terminal: source $SHELL_RC"
        echo "2. Restart VS Code completely"
        echo "3. Open Copilot Chat in VS Code"
        echo "4. Test with: 'Show me my Linear tasks'"
        echo
        echo "If you encounter issues, check the troubleshooting section in SKILL.md"
    else
        echo
        log_error "Setup completed but there were configuration issues"
        echo "Please check the errors above and refer to SKILL.md for troubleshooting"
        exit 1
    fi
}

# Run main function
main "$@"