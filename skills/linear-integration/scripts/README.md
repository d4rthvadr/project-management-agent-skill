# Linear MCP Setup Scripts

Companion scripts to automate the Linear MCP integration setup process.

## Scripts Overview

### VS Code Integration Scripts

#### 🔧 `setup-linear-mcp.sh` (macOS/Linux)
Automated setup script for VS Code on Unix-based systems.

**Features:**
- ✅ Checks prerequisites (Node.js, npx, VS Code)
- ✅ Prompts for Linear API key securely
- ✅ Sets environment variables in shell profile
- ✅ Creates `.vscode/mcp.json` configuration
- ✅ Validates the complete setup
- ✅ Provides troubleshooting feedback

**Usage:**
```bash
# Make executable
chmod +x scripts/setup-linear-mcp.sh

# Run setup
./scripts/setup-linear-mcp.sh
```

#### 🔧 `setup-linear-mcp.ps1` (Windows)
Automated setup script for VS Code on Windows PowerShell.

**Features:**
- ✅ Checks prerequisites (Node.js, npx, VS Code)
- ✅ Prompts for Linear API key securely
- ✅ Sets user environment variables
- ✅ Creates `.vscode/mcp.json` configuration  
- ✅ Validates the complete setup
- ✅ Supports force mode for automation

**Usage:**
```powershell
# Run setup
./scripts/setup-linear-mcp.ps1

# Run with API key parameter
./scripts/setup-linear-mcp.ps1 -ApiKey "lin_api_your_key"

# Run in force mode (skip prompts)
./scripts/setup-linear-mcp.ps1 -Force
```

#### 🔍 `validate-setup.js` (Cross-platform)
Comprehensive validation script to verify VS Code setup.

**Features:**
- ✅ Validates git repository
- ✅ Checks Node.js and npx
- ✅ Verifies VS Code installation
- ✅ Validates `mcp.json` structure and syntax
- ✅ Checks environment variables
- ✅ Tests MCP server availability
- ✅ Tests Linear API connectivity
- ✅ Generates detailed report

**Usage:**
```bash
# Run validation
node scripts/validate-setup.js

# Show help
node scripts/validate-setup.js --help
```

### Claude Desktop Integration Scripts

#### 🔧 `setup-claude-mcp.sh` (macOS/Linux)
Automated setup script for Claude Desktop on Unix-based systems.

**Features:**
- ✅ Checks prerequisites (Node.js, npx, Claude Desktop)
- ✅ Prompts for Linear API key securely
- ✅ Sets system-wide environment variables (via launchctl on macOS)
- ✅ Creates `claude_desktop_config.json` configuration
- ✅ Validates the complete setup
- ✅ macOS-specific Claude app detection

**Usage:**
```bash
# Make executable
chmod +x scripts/setup-claude-mcp.sh

# Run setup
./scripts/setup-claude-mcp.sh
```

#### 🔧 `setup-claude-mcp.ps1` (Windows)
Automated setup script for Claude Desktop on Windows PowerShell.

**Features:**
- ✅ Checks prerequisites (Node.js, npx, Claude Desktop)
- ✅ Prompts for Linear API key securely
- ✅ Sets system-wide environment variables (machine or user level)
- ✅ Creates `claude_desktop_config.json` configuration
- ✅ Validates the complete setup
- ✅ Windows-specific installation path detection

**Usage:**
```powershell
# Run setup
./scripts/setup-claude-mcp.ps1

# Run with API key parameter
./scripts/setup-claude-mcp.ps1 -ApiKey "lin_api_your_key"

# Run in force mode (skip prompts)
./scripts/setup-claude-mcp.ps1 -Force
```

#### 🔍 `validate-claude-setup.js` (Cross-platform)
Comprehensive validation script to verify Claude Desktop setup.

**Features:**
- ✅ Cross-platform config path detection
- ✅ Validates `claude_desktop_config.json` structure and syntax
- ✅ Checks system-wide environment variables
- ✅ Tests MCP server availability
- ✅ Tests Linear API connectivity
- ✅ Platform-specific Claude Desktop detection
- ✅ Generates detailed report

**Usage:**
```bash
# Run validation
node scripts/validate-claude-setup.js

# Show help
node scripts/validate-claude-setup.js --help
```

## Quick Start

### VS Code Integration

#### For macOS/Linux:
```bash
# Clone or download the scripts
cd your-project

# Run VS Code setup
chmod +x skills/linear-integration/scripts/setup-linear-mcp.sh
./skills/linear-integration/scripts/setup-linear-mcp.sh

# Validate setup
node skills/linear-integration/scripts/validate-setup.js
```

#### For Windows:
```powershell
# Run VS Code setup
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
./skills/linear-integration/scripts/setup-linear-mcp.ps1

# Validate setup
node skills/linear-integration/scripts/validate-setup.js
```

### Claude Desktop Integration

#### For macOS/Linux:
```bash
# Run Claude Desktop setup
chmod +x skills/linear-integration/scripts/setup-claude-mcp.sh
./skills/linear-integration/scripts/setup-claude-mcp.sh

# Validate setup
node skills/linear-integration/scripts/validate-claude-setup.js
```

#### For Windows:
```powershell
# Run Claude Desktop setup
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
./skills/linear-integration/scripts/setup-claude-mcp.ps1

# Validate setup
node skills/linear-integration/scripts/validate-claude-setup.js
```

## Script Features

### Security
- 🔐 API keys are handled securely (no logging/echoing)
- 🔐 Environment variables are properly scoped
- 🔐 Backup existing configurations before replacing

### Error Handling
- 🛡️ Comprehensive prerequisite checking
- 🛡️ JSON validation for configurations
- 🛡️ Network timeout handling
- 🛡️ Graceful failure with helpful error messages

### User Experience
- 🎨 Colored output for better readability
- 🎨 Progress indicators and status messages
- 🎨 Interactive prompts with validation
- 🎨 Detailed success/failure feedback

### Validation
- ✅ Configuration file syntax and structure
- ✅ Environment variable presence and format
- ✅ API connectivity testing
- ✅ Tool availability verification

## Manual Execution Alternative

If you prefer to run the setup manually, follow the main [SKILL.md](../SKILL.md) guide.

## Troubleshooting

### Common Issues

**"npx command not found"**
```bash
# Install Node.js which includes npx
# Visit: https://nodejs.org/
```

**"Permission denied" (macOS/Linux)**
```bash
chmod +x scripts/setup-linear-mcp.sh
```

**"Execution policy" error (Windows)**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**"LINEAR_API_KEY not found"**
- Restart terminal/PowerShell after running setup
- Check that the API key starts with `lin_api_`
- Verify the key was copied correctly from Linear

**"mcp.json invalid JSON"**
```bash
# Validate JSON syntax
node scripts/validate-setup.js
```

### Debug Commands

**Check environment variable:**
```bash
# macOS/Linux
echo $LINEAR_API_KEY

# Windows
echo $env:LINEAR_API_KEY
```

**Test MCP server:**
```bash
npx -y linear-mcp-server --help
```

**Validate JSON:**
```bash
cat .vscode/mcp.json | python -m json.tool
```

## Contributing

To improve these scripts:
1. Test on your platform
2. Add error handling for edge cases  
3. Improve user experience
4. Add platform-specific optimizations

## Support

If the scripts don't work:
1. Run the validation script first
2. Check the troubleshooting section
3. Follow the manual setup in [SKILL.md](../SKILL.md)
4. Report issues with platform and error details