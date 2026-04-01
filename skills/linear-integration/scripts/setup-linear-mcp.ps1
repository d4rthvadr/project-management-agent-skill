# Linear MCP Setup Script for VS Code (Windows PowerShell)
# This script automates the setup process for Linear MCP integration on Windows

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

# Check if running in a git repository
function Test-GitRepository {
    try {
        git rev-parse --git-dir | Out-Null
        Write-Success "Running in git repository"
        return $true
    }
    catch {
        Write-Error "This script should be run from within a git repository"
        return $false
    }
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
    
    # Check if VS Code is installed
    try {
        $codeVersion = code --version | Select-Object -First 1
        Write-Success "VS Code found: $codeVersion"
    }
    catch {
        Write-Warning "VS Code CLI not found. Make sure VS Code is installed."
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
        Write-Error "Linear MCP server is not available or timed out"
        Write-Info "This might be normal - the server will be installed when needed"
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
    Write-Host "3. Give it a name (e.g., 'VS Code MCP Integration')"
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

# Set environment variable
function Set-EnvironmentVariable {
    Write-Info "Setting up environment variable..."
    
    # Check if already exists
    $existing = [Environment]::GetEnvironmentVariable("LINEAR_API_KEY", [EnvironmentVariableTarget]::User)
    if ($existing) {
        Write-Warning "LINEAR_API_KEY already exists in user environment"
        if (-not $Force) {
            $replace = Read-Host "Replace existing key? (y/n)"
            if ($replace -notmatch "^[Yy]$") {
                Write-Info "Keeping existing LINEAR_API_KEY"
                return
            }
        }
    }
    
    # Set environment variable for user
    try {
        [Environment]::SetEnvironmentVariable("LINEAR_API_KEY", $script:LinearApiKey, [EnvironmentVariableTarget]::User)
        Write-Success "Added LINEAR_API_KEY to user environment variables"
        
        # Set for current session
        $env:LINEAR_API_KEY = $script:LinearApiKey
        Write-Success "LINEAR_API_KEY set for current session"
    }
    catch {
        Write-Error "Failed to set environment variable: $_"
        throw
    }
}

# Create .vscode directory and mcp.json
function New-McpConfig {
    Write-Info "Creating VS Code MCP configuration..."
    
    # Create .vscode directory if it doesn't exist
    if (-not (Test-Path ".vscode")) {
        New-Item -ItemType Directory -Path ".vscode" | Out-Null
        Write-Success "Created .vscode directory"
    }
    
    # Check if mcp.json already exists
    if (Test-Path ".vscode/mcp.json") {
        Write-Warning "mcp.json already exists"
        if (-not $Force) {
            $replace = Read-Host "Replace existing configuration? (y/n)"
            if ($replace -notmatch "^[Yy]$") {
                Write-Info "Keeping existing mcp.json"
                return
            }
        }
    }
    
    # Create mcp.json
    $mcpConfig = @{
        servers = @{
            linear = @{
                command = "npx"
                args = @("-y", "linear-mcp-server")
                env = @{
                    LINEAR_API_KEY = "`${env:LINEAR_API_KEY}"
                }
            }
        }
    }
    
    try {
        $mcpConfig | ConvertTo-Json -Depth 10 | Set-Content ".vscode/mcp.json" -Encoding UTF8
        Write-Success "Created .vscode/mcp.json"
    }
    catch {
        Write-Error "Failed to create mcp.json: $_"
        throw
    }
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
    
    # Check if mcp.json exists and is valid JSON
    if (-not (Test-Path ".vscode/mcp.json")) {
        Write-Error ".vscode/mcp.json does not exist"
        return $false
    }
    
    # Validate JSON syntax
    try {
        Get-Content ".vscode/mcp.json" | ConvertFrom-Json | Out-Null
        Write-Success ".vscode/mcp.json is valid JSON"
    }
    catch {
        Write-Error ".vscode/mcp.json contains invalid JSON: $_"
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
    Write-Host "🚀 Linear MCP Setup Script for VS Code (Windows)" -ForegroundColor Magenta
    Write-Host "=================================================" -ForegroundColor Magenta
    Write-Host ""
    
    try {
        if (-not (Test-GitRepository)) { exit 1 }
        if (-not (Test-Prerequisites)) { exit 1 }
        
        Test-McpServer
        Get-ApiKey
        Set-EnvironmentVariable
        New-McpConfig
        
        Write-Host ""
        Write-Info "Testing setup..."
        if (Test-Configuration) {
            Write-Host ""
            Write-Success "🎉 Linear MCP setup completed successfully!"
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Restart PowerShell/Command Prompt"
            Write-Host "2. Restart VS Code completely"
            Write-Host "3. Open Copilot Chat in VS Code"
            Write-Host "4. Test with: 'Show me my Linear tasks'"
            Write-Host ""
            Write-Host "If you encounter issues, check the troubleshooting section in SKILL.md"
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