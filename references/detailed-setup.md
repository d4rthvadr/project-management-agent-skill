# Detailed Linear MCP Setup Guide

This document provides comprehensive setup instructions for Linear MCP integration. For quick automated setup, use the scripts in the `/scripts` directory.

## Manual Setup for VS Code

### Prerequisites
- VS Code with GitHub Copilot extension
- Linear account with API access
- Node.js installed (for npx)

### Step 1: Get Linear API Key

1. **Login to Linear** → Go to your Linear workspace
2. **Navigate to Settings** → Click your profile → Settings
3. **Go to API section** → Settings → API → Personal API keys  
4. **Create API Key**:
   - Click "Create new API key"
   - Give it a name (e.g., "VS Code MCP Integration")
   - Copy the generated key (starts with `lin_api_`)

### Step 2: Set Environment Variable

**For macOS/Linux (bash/zsh):**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export LINEAR_API_KEY="lin_api_your_key_here"

# Reload shell
source ~/.zshrc  # or source ~/.bash_profile
```

**For Windows:**
```cmd
# Set permanently
setx LINEAR_API_KEY "lin_api_your_key_here"

# Or for current session
set LINEAR_API_KEY=lin_api_your_key_here
```

### Step 3: Create MCP Configuration

1. **Create `.vscode/mcp.json`** in your project root:
```json
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
```

2. **Verify the file structure**:
```
your-project/
├── .vscode/
│   └── mcp.json
└── ... (your project files)
```

### Step 4: Test the Setup

1. **Restart VS Code** completely (to pick up new MCP config)

2. **Open Copilot Chat**:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "GitHub Copilot: Open Chat"
   - Press Enter

3. **Test with simple query**:
   ```
   Show me my currently assigned Linear tasks
   ```

4. **If successful, try more commands**:
   ```
   What Linear issues are in my backlog?
   Update Linear task ABC-123 description to "Updated requirements"
   ```

## Manual Setup for Claude Desktop

Claude Desktop offers two methods for Linear MCP integration: the new Desktop Extensions (recommended) and traditional JSON configuration.

### Method 1: Desktop Extensions (Recommended - 2025+)

**🚀 Easiest Setup - Single Click Installation**

1. **Open Claude Desktop Settings**
   - Launch Claude Desktop application
   - Navigate to **Settings** → **Extensions**

2. **Browse Extensions**
   - Click **"Browse extensions"** to view the directory
   - Look for **"Linear"** or **"Linear MCP"** extension
   - Click **"Install"** on the Linear extension

3. **Configure API Key**
   - After installation, configure your Linear API key through the user-friendly interface
   - Enter your `lin_api_` key when prompted

4. **Verify Installation**
   - Start a new chat in Claude Desktop
   - Look for a **hammer icon** at the bottom of the chat window
   - The number next to it indicates available MCP tools
   - Click the hammer to see Linear tools listed

### Method 2: JSON Configuration (Advanced)

**For users who prefer manual configuration or need custom setups:**

#### Step 1: Get Linear API Key
Same as VS Code setup - get your `lin_api_` key from Linear → Settings → API → Personal API keys

#### Step 2: Set System Environment Variable

**macOS/Linux:**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export LINEAR_API_KEY="lin_api_your_key_here"

# Reload and verify
source ~/.zshrc
echo $LINEAR_API_KEY
```

**Windows:**
```cmd
# Set system environment variable
setx LINEAR_API_KEY "lin_api_your_key_here" /M

# Verify (restart terminal first)
echo %LINEAR_API_KEY%
```

#### Step 3: Create Claude MCP Configuration

1. **Open Claude Desktop Config**
   - In Claude Desktop: Click **Developer** → **Edit Config**
   - Or manually edit the file at:

**File Locations:**
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

2. **Add Linear MCP Configuration**:
```json
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
```

**⚠️ Important:** Leave `LINEAR_API_KEY` empty in the JSON - Claude will read from system environment variables.

#### Step 4: Restart Claude Desktop
- Completely quit and restart Claude Desktop
- The system environment variable needs to be available to Claude

#### Step 5: Verify Setup
1. **Check Tools Availability**
   - Start a new conversation
   - Look for hammer icon at bottom of chat
   - Click to see Linear tools listed

2. **Test Linear Integration**
   ```
   Show me my current Linear tasks
   ```

## Common Issues & Solutions

### Issue: "LINEAR_API_KEY environment variable is required"
**Solution**: 
- Ensure you've set the environment variable in your shell profile
- Restart your terminal and VS Code completely
- Verify with: `echo $LINEAR_API_KEY` (should show your key)

### Issue: "linear-mcp-server not found"
**Solution**: 
- Ensure Node.js and npm are installed
- Try manual install: `npm install -g linear-mcp-server`
- Check if npx is available: `npx --version`

### Issue: Copilot Chat doesn't recognize Linear commands
**Solution**:
- Restart VS Code completely
- Check that `.vscode/mcp.json` is in your project root
- Verify JSON syntax is correct (use JSON validator)
- Try opening a file in the project before using Copilot Chat

### Issue: "Authentication failed" or "Invalid API key"
**Solution**:
- Generate a new Linear API key
- Ensure the key starts with `lin_api_`
- Check for extra spaces in environment variable
- Verify you have access to the Linear workspace

## Advanced Configuration

### Team-Specific Setup
If you work with multiple Linear teams, you can specify team context:

```json
{
  "servers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "linear-mcp-server"],
      "env": {
        "LINEAR_API_KEY": "${env:LINEAR_API_KEY}",
        "LINEAR_TEAM_KEY": "${env:LINEAR_TEAM_KEY}"
      }
    }
  }
}
```

### Project-Specific Filters
Add environment variables for project-specific workflows:

```bash
export LINEAR_DEFAULT_PROJECT="Project Name"
export LINEAR_DEFAULT_TEAM="TEAM"
```

## Usage Examples

### Getting Tasks
```
# Basic queries
"What are my Linear tasks?"
"Show me my assigned Linear issues"
"List Linear tasks in progress"

# Filtered queries  
"Show me high-priority Linear tasks"
"What Linear issues are overdue?"
"List my Linear tasks for the current project"
```

### Updating Tasks
```
# Update descriptions
"Update Linear task ABC-123 description to include API endpoints"

# Change status
"Mark Linear task XYZ-456 as in progress"

# Add comments
"Add comment to Linear issue DEF-789: Testing completed successfully"
```

### Creating Tasks
```
# Create new tasks
"Create a Linear task titled 'Fix authentication bug' assigned to me"

# Create subtasks
"Break down Linear task ABC-123 into implementation subtasks"

# From planning
"Create Linear tasks for each step in this development plan: [plan]"
```

## Claude vs VS Code Differences

| Feature | VS Code | Claude Desktop |
|---------|---------|----------------|
| **Configuration** | Project-specific (`.vscode/mcp.json`) | Global system (`claude_desktop_config.json`) |
| **Interface** | Copilot Chat window | Direct conversation |
| **Setup Method** | Manual JSON only | Extensions + JSON options |
| **Environment** | Shell environment | System environment |
| **Scope** | Per workspace | All conversations |
| **Usage** | "Show me..." commands | Natural conversation |

## Troubleshooting Commands

**Test MCP server directly:**
```bash
npx -y linear-mcp-server --help
```

**Check environment variable:**
```bash
echo $LINEAR_API_KEY
```

**Validate JSON configuration:**
```bash
cat .vscode/mcp.json | python -m json.tool
```

**Test Linear API access:**
```bash
curl -H "Authorization: Bearer $LINEAR_API_KEY" https://api.linear.app/graphql -d '{"query":"{ viewer { name } }"}'
```