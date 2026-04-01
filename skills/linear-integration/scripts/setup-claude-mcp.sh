#!/bin/bash

# Linear MCP Setup Script for Claude Desktop
# This script automates the setup process for Linear MCP integration with Claude Desktop

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

log_header() {
    echo -e "${MAGENTA}$1${NC}"
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
    
    # Check if Claude Desktop is installed (macOS specific)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ -d "/Applications/Claude.app" ]]; then
            log_success "Claude Desktop found in Applications"
        else
            log_warning "Claude Desktop not found in /Applications/Claude.app"
            log_info "Please download Claude Desktop from https://claude.ai/desktop"
        fi
    else
        log_info "Skipping Claude Desktop check on non-macOS system"
    fi
}

# Test Linear MCP server availability
test_mcp_server() {
    log_info "Testing Linear MCP server availability..."
    
    if timeout 10s npx -y linear-mcp-server --help > /dev/null 2>&1; then
        log_success "Linear MCP server is available"
    else
        log_warning "Linear MCP server test timed out (this might be normal)"
        log_info "The server will be installed when needed by Claude Desktop"
    fi
}

# Get Linear API key from user
get_api_key() {
    echo
    log_info "Linear API Key Setup"
    echo "To get your Linear API key:"
    echo "1. Go to Linear → Settings → API → Personal API keys"
    echo "2. Click 'Create new API key'"
    echo "3. Give it a name (e.g., 'Claude Desktop MCP Integration')"
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

# Set system-wide environment variable
set_system_environment_variable() {
    log_info "Setting up system-wide environment variable..."
    
    # Detect shell and system
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - need to set in multiple places for system-wide access
        SHELL_RC=""
        
        if [[ -n "$ZSH_VERSION" ]]; then
            SHELL_RC="$HOME/.zshrc"
            SHELL_NAME="zsh"
        elif [[ -n "$BASH_VERSION" ]]; then
            SHELL_RC="$HOME/.bash_profile"
            SHELL_NAME="bash"
        else
            SHELL_RC="$HOME/.profile"
            SHELL_NAME="shell"
        fi
        
        log_info "Detected $SHELL_NAME shell on macOS"
        
        # Set in shell profile
        if grep -q "LINEAR_API_KEY" "$SHELL_RC" 2>/dev/null; then
            log_warning "LINEAR_API_KEY already exists in $SHELL_RC"
            read -p "Replace existing key? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sed -i.bak '/export LINEAR_API_KEY/d' "$SHELL_RC"
                log_info "Removed existing LINEAR_API_KEY"
            else
                log_info "Keeping existing LINEAR_API_KEY in shell profile"
            fi
        fi
        
        if ! grep -q "LINEAR_API_KEY=\"$LINEAR_API_KEY\"" "$SHELL_RC" 2>/dev/null; then
            echo "export LINEAR_API_KEY=\"$LINEAR_API_KEY\"" >> "$SHELL_RC"
            log_success "Added LINEAR_API_KEY to $SHELL_RC"
        fi
        
        # Also set using launchctl for macOS system-wide access
        log_info "Setting system-wide environment variable for Claude Desktop..."
        launchctl setenv LINEAR_API_KEY "$LINEAR_API_KEY" 2>/dev/null || log_warning "Could not set via launchctl (might need admin rights)"
        
        # Set for current session
        export LINEAR_API_KEY="$LINEAR_API_KEY"
        log_success "LINEAR_API_KEY set for current session"
        
    else
        # Linux/other Unix
        PROFILE_FILE="$HOME/.profile"
        
        if grep -q "LINEAR_API_KEY" "$PROFILE_FILE" 2>/dev/null; then
            log_warning "LINEAR_API_KEY already exists in $PROFILE_FILE"
            read -p "Replace existing key? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sed -i.bak '/export LINEAR_API_KEY/d' "$PROFILE_FILE"
                log_info "Removed existing LINEAR_API_KEY"
            fi
        fi
        
        echo "export LINEAR_API_KEY=\"$LINEAR_API_KEY\"" >> "$PROFILE_FILE"
        log_success "Added LINEAR_API_KEY to $PROFILE_FILE"
        
        # Set for current session
        export LINEAR_API_KEY="$LINEAR_API_KEY"
        log_success "LINEAR_API_KEY set for current session"
    fi
}

# Create Claude Desktop MCP configuration
create_claude_mcp_config() {
    log_info "Creating Claude Desktop MCP configuration..."
    
    # Determine config path based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CONFIG_DIR="$HOME/Library/Application Support/Claude"
        CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    else
        log_error "This script currently supports macOS. For other systems, manually edit the config file."
        log_info "Config file location for your system may vary."
        return 1
    fi
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        log_success "Created Claude config directory: $CONFIG_DIR"
    fi
    
    # Check if config file already exists
    if [[ -f "$CONFIG_FILE" ]]; then
        log_warning "Claude Desktop config file already exists"
        log_info "Current config at: $CONFIG_FILE"
        
        # Check if Linear MCP is already configured
        if grep -q '"linear"' "$CONFIG_FILE" 2>/dev/null; then
            log_warning "Linear MCP configuration already exists"
            read -p "Replace existing Linear configuration? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Keeping existing Linear configuration"
                return 0
            fi
        fi
        
        # Backup existing config
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing config"
    fi
    
    # Create or update configuration
    if [[ ! -f "$CONFIG_FILE" ]]; then
        # Create new config file
        cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "linear-mcp-server"],
      "env": {
        "LINEAR_API_KEY": ""
      }
    }
  }
}
EOF
        log_success "Created new Claude Desktop config file"
    else
        # Update existing config file (this is more complex - for now, show manual instructions)
        log_warning "Existing config file found. Please manually add Linear MCP configuration:"
        echo
        echo "Add this to your mcpServers section in $CONFIG_FILE:"
        echo '    "linear": {'
        echo '      "command": "npx",'
        echo '      "args": ["-y", "linear-mcp-server"],'
        echo '      "env": {'
        echo '        "LINEAR_API_KEY": ""'
        echo '      }'
        echo '    }'
        echo
        read -p "Press Enter after manually updating the config file..."
    fi
    
    log_success "Claude Desktop MCP configuration completed"
    log_info "Config file location: $CONFIG_FILE"
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
    
    # Check if Claude config exists
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    else
        log_warning "Skipping config file check on non-macOS system"
        return 0
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Claude Desktop config file does not exist: $CONFIG_FILE"
        return 1
    fi
    
    # Validate JSON syntax
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
            log_success "Claude Desktop config file is valid JSON"
        else
            log_error "Claude Desktop config file contains invalid JSON"
            return 1
        fi
    elif command -v node &> /dev/null; then
        if node -e "JSON.parse(require('fs').readFileSync('$CONFIG_FILE', 'utf8'))" 2>/dev/null; then
            log_success "Claude Desktop config file is valid JSON"
        else
            log_error "Claude Desktop config file contains invalid JSON"
            return 1
        fi
    else
        log_warning "Could not validate JSON syntax (no python3 or node found)"
    fi
    
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
    log_header "🚀 Linear MCP Setup Script for Claude Desktop"
    log_header "=============================================="
    echo
    
    check_prerequisites
    test_mcp_server
    get_api_key
    set_system_environment_variable
    create_claude_mcp_config
    
    echo
    log_info "Testing setup..."
    if test_configuration; then
        echo
        log_success "🎉 Linear MCP setup for Claude Desktop completed successfully!"
        echo
        log_header "Next steps:"
        echo "1. Restart Claude Desktop completely (quit and reopen)"
        echo "2. Start a new conversation in Claude Desktop"
        echo "3. Look for a hammer icon at the bottom of the chat"
        echo "4. Test with: 'Show me my Linear tasks'"
        echo
        log_info "The hammer icon should show a number indicating available MCP tools"
        log_info "If you encounter issues, check the troubleshooting section in SKILL.md"
        
        # macOS specific restart instructions
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo
            log_info "To restart Claude Desktop on macOS:"
            echo "1. Cmd+Q to quit Claude Desktop completely"
            echo "2. Reopen from Applications or Spotlight"
        fi
        
    else
        echo
        log_error "Setup completed but there were configuration issues"
        echo "Please check the errors above and refer to SKILL.md for troubleshooting"
        exit 1
    fi
}

# Run main function
main "$@"