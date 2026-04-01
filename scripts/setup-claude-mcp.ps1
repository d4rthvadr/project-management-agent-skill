# Linear MCP Setup Script for Claude Desktop (Windows PowerShell)
# This script automates the setup process for Linear MCP integration with Claude Desktop

param(
    [Parameter(HelpMessage="Linear API Key (if not provided, will prompt)")]
    [string]$ApiKey,
    
    [Parameter(HelpMessage="Skip interactive prompts")]
    [switch]$Force
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$WarningColor = "Yellow"
$InfoColor = "Cyan"
$HeaderColor = "Magenta"

# Logging functions
function Write-Info($message) {
    Write-Host "ℹ️  $message" -ForegroundColor $InfoColor
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor $SuccessColor
}

function Write-Warning($message) {
    Write-Host "⚠️  $message" -ForegroundColor $WarningColor
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor $ErrorColor
}

function Write-Header($message) {
    Write-Host $message -ForegroundColor $HeaderColor
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check Node.js
    try {
        $nodeVersion = node --version
        Write-Success "Node.js found: $nodeVersion"
    }
    catch {
        Write-Error "Node.js is not installed. Please install Node.js first."
        return $false
    }
    
    # Check npm/npx
    try {
        $npxVersion = npx --version
        Write-Success "npx found: $npxVersion"
    }
    catch {
        Write-Error "npx is not available. Please install npm/npx first."
        return $false
    }
    
    # Check if Claude Desktop is installed
    $claudeDesktopPaths = @(
        "$env:LOCALAPPDATA\Claude\Claude.exe",
        "$env:PROGRAMFILES\Claude\Claude.exe",
        "${env:PROGRAMFILES(X86)}\Claude\Claude.exe"
    )
    
    $claudeFound = $false
    foreach ($path in $claudeDesktopPaths) {
        if (Test-Path $path) {
            Write-Success "Claude Desktop found at: $path"
            $claudeFound = $true
            break
        }
    }
    
    if (-not $claudeFound) {
        Write-Warning "Claude Desktop not found in common locations"
        Write-Info "Please download Claude Desktop from https://claude.ai/desktop"
    }
    
    return $true
}

# Test Linear MCP server availability
function Test-McpServer {
    Write-Info "Testing Linear MCP server availability..."
    
    try {
        $job = Start-Job -ScriptBlock { npx -y linear-mcp-server --help }
        Wait-Job $job -Timeout 10 | Out-Null
        Stop-Job $job -PassThru | Remove-Job
        Write-Success "Linear MCP server is available"
    }
    catch {
        Write-Warning "Linear MCP server test timed out (this might be normal)"
        Write-Info "The server will be installed when needed by Claude Desktop"
    }
}

# Get Linear API key from user
function Get-ApiKey {
    if ($ApiKey) {
        $script:LinearApiKey = $ApiKey
        return
    }
    
    Write-Host ""
    Write-Info "Linear API Key Setup"
    Write-Host "To get your Linear API key:"
    Write-Host "1. Go to Linear → Settings → API → Personal API keys"
    Write-Host "2. Click 'Create new API key'"
    Write-Host "3. Give it a name (e.g., 'Claude Desktop MCP Integration')"
    Write-Host "4. Copy the generated key (starts with 'lin_api_')"
    Write-Host ""
    
    do {
        $apiKey = Read-Host "Enter your Linear API key" -AsSecureString
        $apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))
        
        if ([string]::IsNullOrEmpty($apiKeyPlain)) {
            Write-Error "API key cannot be empty"
            continue
        }
        
        if (-not $apiKeyPlain.StartsWith("lin_api_")) {
            Write-Warning "API key should start with 'lin_api_'. Are you sure this is correct?"
            if (-not $Force) {
                $continue = Read-Host "Continue anyway? (y/n)"
                if ($continue -notmatch "^[Yy]$") {
                    continue
                }
            }
        }
        
        $script:LinearApiKey = $apiKeyPlain
        break
    } while ($true)
}

# Set system-wide environment variable
function Set-SystemEnvironmentVariable {
    Write-Info "Setting up system-wide environment variable..."
    
    # Check if already exists
    $existing = [Environment]::GetEnvironmentVariable("LINEAR_API_KEY", [EnvironmentVariableTarget]::Machine)
    if (-not $existing) {
        $existing = [Environment]::GetEnvironmentVariable("LINEAR_API_KEY", [EnvironmentVariableTarget]::User)
    }
    
    if ($existing) {
        Write-Warning "LINEAR_API_KEY already exists in environment variables"
        if (-not $Force) {
            $replace = Read-Host "Replace existing key? (y/n)"
            if ($replace -notmatch "^[Yy]$") {
                Write-Info "Keeping existing LINEAR_API_KEY"
                return
            }
        }
    }
    
    # Try to set at machine level first (requires admin), fall back to user level
    try {
        [Environment]::SetEnvironmentVariable("LINEAR_API_KEY", $script:LinearApiKey, [EnvironmentVariableTarget]::Machine)
        Write-Success "Added LINEAR_API_KEY to system environment variables (machine-wide)"
    }
    catch {
        Write-Warning "Could not set machine-wide environment variable (admin rights required)"
        try {
            [Environment]::SetEnvironmentVariable("LINEAR_API_KEY", $script:LinearApiKey, [EnvironmentVariableTarget]::User)
            Write-Success "Added LINEAR_API_KEY to user environment variables"
        }
        catch {
            Write-Error "Failed to set environment variable: $_"
            throw
        }
    }
    
    # Set for current session
    $env:LINEAR_API_KEY = $script:LinearApiKey
    Write-Success "LINEAR_API_KEY set for current session"
}

# Create Claude Desktop MCP configuration
function New-ClaudeMcpConfig {
    Write-Info "Creating Claude Desktop MCP configuration..."
    
    # Determine config path
    $configDir = "$env:APPDATA\Claude"
    $configFile = "$configDir\claude_desktop_config.json"
    
    # Create config directory if it doesn't exist
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Success "Created Claude config directory: $configDir"
    }
    
    # Check if config file already exists
    if (Test-Path $configFile) {
        Write-Warning "Claude Desktop config file already exists"
        Write-Info "Current config at: $configFile"
        
        # Check if Linear MCP is already configured
        $existingContent = Get-Content $configFile -Raw -ErrorAction SilentlyContinue
        if ($existingContent -and $existingContent.Contains('"linear"')) {
            Write-Warning "Linear MCP configuration already exists"
            if (-not $Force) {
                $replace = Read-Host "Replace existing Linear configuration? (y/n)"
                if ($replace -notmatch "^[Yy]$") {
                    Write-Info "Keeping existing Linear configuration"
                    return
                }
            }
        }
        
        # Backup existing config
        $backupFile = "$configFile.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $configFile $backupFile
        Write-Info "Backed up existing config to: $backupFile"
    }
    
    # Create or update configuration
    if (-not (Test-Path $configFile)) {
        # Create new config file
        $mcpConfig = @{
            mcpServers = @{
                linear = @{
                    command = "npx"
                    args = @("-y", "linear-mcp-server")
                    env = @{
                        LINEAR_API_KEY = ""
                    }
                }
            }
        }
        
        try {
            $mcpConfig | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
            Write-Success "Created new Claude Desktop config file"
        }
        catch {
            Write-Error "Failed to create config file: $_"
            throw
        }
    }
    else {
        # For existing files, show manual instructions (complex JSON manipulation)
        Write-Warning "Existing config file found. Please manually add Linear MCP configuration:"
        Write-Host ""
        Write-Host "Add this to your mcpServers section in $configFile :" -ForegroundColor Yellow
        Write-Host '    "linear": {' -ForegroundColor Green
        Write-Host '      "command": "npx",' -ForegroundColor Green
        Write-Host '      "args": ["-y", "linear-mcp-server"],' -ForegroundColor Green
        Write-Host '      "env": {' -ForegroundColor Green
        Write-Host '        "LINEAR_API_KEY": ""' -ForegroundColor Green
        Write-Host '      }' -ForegroundColor Green
        Write-Host '    }' -ForegroundColor Green
        Write-Host ""
        
        if (-not $Force) {
            Read-Host "Press Enter after manually updating the config file"
        }
    }
    
    Write-Success "Claude Desktop MCP configuration completed"
    Write-Info "Config file location: $configFile"
}

# Test the configuration
function Test-Configuration {
    Write-Info "Testing configuration..."
    
    # Check if environment variable is set
    if ([string]::IsNullOrEmpty($env:LINEAR_API_KEY)) {
        Write-Error "LINEAR_API_KEY is not set in current session"
        return $false
    }
    Write-Success "LINEAR_API_KEY is set in current session"
    
    # Check if Claude config exists
    $configFile = "$env:APPDATA\Claude\claude_desktop_config.json"
    if (-not (Test-Path $configFile)) {
        Write-Error "Claude Desktop config file does not exist: $configFile"
        return $false
    }
    
    # Validate JSON syntax
    try {
        Get-Content $configFile | ConvertFrom-Json | Out-Null
        Write-Success "Claude Desktop config file is valid JSON"
    }
    catch {
        Write-Error "Claude Desktop config file contains invalid JSON: $_"
        return $false
    }
    
    # Test Linear API access (optional)
    Write-Info "Testing Linear API access..."
    try {
        $headers = @{
            "Authorization" = "Bearer $env:LINEAR_API_KEY"
            "Content-Type" = "application/json"
        }
        $body = @{
            query = "{ viewer { name } }"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "https://api.linear.app/graphql" -Method Post -Headers $headers -Body $body -TimeoutSec 10
        if ($response.data) {
            Write-Success "Linear API access confirmed"
        }
        else {
            Write-Warning "Could not verify Linear API access. Check your API key."
        }
    }
    catch {
        Write-Warning "Could not test Linear API access: $_"
    }
    
    return $true
}

# Main setup function
function Main {
    Write-Header "🚀 Linear MCP Setup Script for Claude Desktop (Windows)"
    Write-Header "===================================================="
    Write-Host ""
    
    try {
        if (-not (Test-Prerequisites)) { exit 1 }
        
        Test-McpServer
        Get-ApiKey
        Set-SystemEnvironmentVariable
        New-ClaudeMcpConfig
        
        Write-Host ""
        Write-Info "Testing setup..."
        if (Test-Configuration) {
            Write-Host ""
            Write-Success "🎉 Linear MCP setup for Claude Desktop completed successfully!"
            Write-Host ""
            Write-Header "Next steps:"
            Write-Host "1. Restart Claude Desktop completely (Alt+F4 or close from taskbar)"
            Write-Host "2. Reopen Claude Desktop"
            Write-Host "3. Start a new conversation"
            Write-Host "4. Look for a hammer icon at the bottom of the chat"
            Write-Host "5. Test with: 'Show me my Linear tasks'"
            Write-Host ""
            Write-Info "The hammer icon should show a number indicating available MCP tools"
            Write-Info "If you encounter issues, check the troubleshooting section in SKILL.md"
            Write-Host ""
            Write-Warning "Important: You may need to restart Windows for system environment variables to take effect"
            
        }
        else {
            Write-Host ""
            Write-Error "Setup completed but there were configuration issues"
            Write-Host "Please check the errors above and refer to SKILL.md for troubleshooting"
            exit 1
        }
    }
    catch {
        Write-Error "Setup failed: $_"
        exit 1
    }
}

# Run main function
Main