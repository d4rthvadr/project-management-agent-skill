# Linear Skill for AI Agents

A [skills.sh](https://skills.sh) compatible skill that enables AI agents to interact with Linear project management platform through VS Code Copilot Chat and Claude Desktop.

## Installation

### Via skills.sh (Recommended)
```bash
npx skills add linear-skill
```

### Manual Installation
1. Clone or download this repository
2. Place in your skills directory
3. Follow the setup instructions in [`SKILL.md`](SKILL.md)

## What This Skill Enables

Once configured, AI agents can:

- **📋 Get Tasks**: "What are my currently assigned Linear tasks?"
- **✏️ Update Tasks**: "Update Linear task ABC-123 to include new requirements" 
- **➕ Create Tasks**: "Create Linear subtasks from this development plan"
- **🔄 Manage Workflow**: "Show me high-priority Linear issues in backlog"

## Quick Start

### Automated Setup (Recommended)

**For VS Code:**
```bash
./scripts/setup-linear-mcp.sh    # macOS/Linux
./scripts/setup-linear-mcp.ps1   # Windows
```

**For Claude Desktop:**
```bash
./scripts/setup-claude-mcp.sh    # macOS/Linux  
./scripts/setup-claude-mcp.ps1   # Windows
```

**Validate Setup:**
```bash
node scripts/validate-setup.js         # VS Code
node scripts/validate-claude-setup.js  # Claude Desktop
```

### Manual Setup Overview

1. **Get Linear API Key**: Linear → Settings → API → Personal API keys
2. **Set Environment Variable**: `export LINEAR_API_KEY="lin_api_your_key"`
3. **Configure MCP Integration**: 
   - **VS Code**: Create `.vscode/mcp.json`
   - **Claude Desktop**: Update `claude_desktop_config.json`
4. **Test**: Ask your agent "Show me my Linear tasks"

📖 **[Complete Setup Guide →](SKILL.md)**

## Platform Support

| Platform | Configuration | Interface | Scope |
|----------|--------------|-----------|--------|
| **VS Code** | Project `.vscode/mcp.json` | Copilot Chat | Per workspace |
| **Claude Desktop** | Global config file | Direct conversation | All chats |

## Example Workflows

### Development Integration
```
"Create Linear tasks for each item in this code review"
"Update my current Linear task with today's progress"
"Show Linear tasks related to the authentication module"
"Break down this feature request into Linear subtasks"
```

### Project Management
```
"What Linear issues are blocking the current sprint?"
"List overdue Linear tasks assigned to me"
"Create a Linear task for this bug report"
"Update Linear task status to completed"
```

## Repository Structure

```
linear-skill/
├── SKILL.md                     # Main skill definition with YAML frontmatter
├── README.md                    # This file - skills.sh compatibility info
├── scripts/                     # Automated setup and validation tools
│   ├── README.md               # Script documentation
│   ├── setup-linear-mcp.sh     # VS Code setup (Unix)
│   ├── setup-linear-mcp.ps1    # VS Code setup (Windows)
│   ├── setup-claude-mcp.sh     # Claude Desktop setup (Unix)
│   ├── setup-claude-mcp.ps1    # Claude Desktop setup (Windows)
│   ├── validate-setup.js       # VS Code validation
│   └── validate-claude-setup.js # Claude Desktop validation
└── references/                  # Detailed documentation
    └── detailed-setup.md       # Comprehensive setup instructions
```

## Skills.sh Compatibility

This skill follows the [Agent Skills](https://agentskills.io) open standard:

- ✅ **YAML Frontmatter**: Proper `name`, `description`, and metadata
- ✅ **Progressive Disclosure**: Core instructions in `SKILL.md`, detailed docs in `references/`
- ✅ **Bundled Resources**: Setup scripts and validation tools included
- ✅ **Size Optimized**: Main skill file under 500 lines
- ✅ **Platform Agnostic**: Works across VS Code, Claude Desktop, and other MCP-compatible agents

## Contributing

This skill is designed to be discoverable and usable through the skills.sh ecosystem. To contribute:

1. Fork this repository
2. Make improvements to the skill definition or setup scripts
3. Test across supported platforms (VS Code, Claude Desktop)
4. Submit a pull request

## License

Apache-2.0 License - see skill metadata in `SKILL.md`

## Support

- 📖 **Setup Issues**: Check [`SKILL.md`](SKILL.md) troubleshooting section
- 🔧 **Script Problems**: Review [`scripts/README.md`](scripts/README.md) 
- 📋 **Detailed Guides**: See [`references/detailed-setup.md`](references/detailed-setup.md)

---

**Ready to supercharge your Linear workflow with AI agents?** Install this skill and start managing tasks through natural language!