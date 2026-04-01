---
name: linear-skill
description: "Set up Linear MCP integration to enable AI agents to interact with Linear tasks through VS Code Copilot Chat and Claude Desktop. Use when user mentions Linear, project management, task tracking, wants to connect development environment with Linear workflow, or asks about setting up Linear integration with AI agents."
license: Apache-2.0
metadata:
  version: "1.0.0"
  author: "linear-skill-team"
  last-updated: "2025-04-01"
---

# Linear Integration Skill

## Overview

This skill helps you set up Linear MCP (Model Context Protocol) integration to enable AI agents to interact with Linear tasks through VS Code Copilot Chat and Claude Desktop. Once configured, agents can get your assigned tasks, update descriptions, create subtasks, and more - all through natural language commands.

## What This Enables

- **Get Tasks**: "What are my currently assigned Linear tasks?"
- **Update Tasks**: "Update the description of Linear task ABC-123 to include new requirements"
- **Create Tasks**: "Create Linear subtasks from this development plan"
- **Task Management**: "Show me my high-priority Linear issues in backlog"

## Quick Setup (Automated)

🚀 **Use the companion scripts for automated setup:**

### For VS Code on macOS/Linux:
```bash
chmod +x scripts/setup-linear-mcp.sh
./scripts/setup-linear-mcp.sh
```

### For VS Code on Windows:
```powershell
./scripts/setup-linear-mcp.ps1
```

### For Claude Desktop on macOS/Linux:
```bash
chmod +x scripts/setup-claude-mcp.sh
./scripts/setup-claude-mcp.sh
```

### For Claude Desktop on Windows:
```powershell
./scripts/setup-claude-mcp.ps1
```

### Validate Setup:
```bash
# For VS Code
node scripts/validate-setup.js

# For Claude Desktop  
node scripts/validate-claude-setup.js
```

See [`scripts/README.md`](scripts/README.md) for detailed script documentation.

## Manual Setup Overview

### Prerequisites
- VS Code with GitHub Copilot extension OR Claude Desktop
- Linear account with API access
- Node.js installed (for npx)

### Quick Steps
1. **Get Linear API Key**: Linear → Settings → API → Personal API keys → Create new key
2. **Set Environment Variable**: `export LINEAR_API_KEY="lin_api_your_key_here"`
3. **Configure MCP**: 
   - **VS Code**: Create `.vscode/mcp.json` with Linear server config
   - **Claude Desktop**: Add Linear server to `claude_desktop_config.json`
4. **Restart and Test**: Restart your environment and test with "Show me my Linear tasks"

📖 **[Complete Manual Setup Guide →](references/detailed-setup.md)**

## Example Usage

Once configured, you can use natural language to interact with Linear:

### Getting Information
```
"What Linear tasks are assigned to me?"
"Show me high-priority Linear issues" 
"List my Linear tasks in progress"
"What Linear issues are overdue for the current sprint?"
```

### Making Updates  
```
"Update Linear task ABC-123 description to include the new API requirements"
"Change the status of Linear task XYZ-456 to completed"
"Add comment to Linear issue DEF-789: Testing completed successfully"
```

### Creating Tasks
```
"Create a Linear task titled 'Fix authentication bug' and assign it to me"
"Break down Linear task ABC-123 into implementation subtasks"
"Based on this code review feedback, create Linear tasks for each issue"
```

### Development Workflow Integration
```
"Update my current Linear task with progress notes from today's development"
"Create Linear tasks for each step in this development plan"
"Show me Linear tasks related to the authentication module"
```

## Platform Support

| Platform | Configuration | Interface | Scope |
|----------|--------------|-----------|-------|
| **VS Code** | Project-specific `.vscode/mcp.json` | Copilot Chat window | Per workspace |
| **Claude Desktop** | Global `claude_desktop_config.json` | Direct conversation | All conversations |

## Validation & Testing

After setup, verify your integration works:

1. **Check Tools Available**:
   - **VS Code**: Look for Linear tools in Copilot Chat
   - **Claude Desktop**: Check for hammer icon showing available MCP tools

2. **Test Basic Query**: `"Show me my current Linear tasks"`

3. **Run Validation Script**:
   ```bash
   # Comprehensive validation
   node scripts/validate-setup.js      # VS Code
   node scripts/validate-claude-setup.js  # Claude Desktop
   ```

## Troubleshooting

### Common Issues

**"LINEAR_API_KEY environment variable is required"**
- Set environment variable: `export LINEAR_API_KEY="lin_api_your_key"`
- Restart terminal and application completely

**"linear-mcp-server not found"**  
- Install Node.js: https://nodejs.org/
- Test npx: `npx --version`

**"Authentication failed"**
- Verify API key starts with `lin_api_`
- Generate new key in Linear → Settings → API

**VS Code: "Copilot Chat doesn't recognize Linear commands"**
- Restart VS Code completely
- Verify `.vscode/mcp.json` exists and has correct JSON syntax
- Open a file in the project before using Copilot Chat

**Claude Desktop: "No Linear tools available"**
- Check config file location and syntax
- Ensure `LINEAR_API_KEY` is set as system environment variable
- Restart Claude Desktop completely

### Debug Commands
```bash
# Test MCP server
npx -y linear-mcp-server --help

# Check environment  
echo $LINEAR_API_KEY

# Validate JSON
cat .vscode/mcp.json | python -m json.tool

# Test Linear API
curl -H "Authorization: Bearer $LINEAR_API_KEY" https://api.linear.app/graphql -d '{"query":"{ viewer { name } }"}'
```

## Files & Resources

- `SKILL.md` - This skill overview (you are here)
- `scripts/` - Automated setup and validation scripts
- `references/detailed-setup.md` - Complete manual setup instructions
- `scripts/README.md` - Script documentation

## Support

If you encounter issues:
1. Run the validation scripts first
2. Check the troubleshooting section above  
3. Review the detailed setup guide in `references/`
4. Ensure Linear workspace permissions are correct

This integration enables powerful agent-driven Linear task management directly from your development environment.