# Skills.sh Publishing Guide

This guide explains how to publish your Linear skill to the skills.sh ecosystem to make it discoverable and installable by other developers.

## Skills.sh Overview

[Skills.sh](https://skills.sh) is the open agent skills ecosystem where skills are reusable capabilities for AI agents. Skills appear on the platform through installation telemetry - **no manual registry submission is required**.

## Prerequisites ✅

Your skill is already skills.sh compatible:

- ✅ **YAML Frontmatter**: Valid with required `name` and `description` fields
- ✅ **File Structure**: Follows Agent Skills open standard
- ✅ **Size Optimization**: Main SKILL.md under 500 lines (190 lines)
- ✅ **Progressive Disclosure**: Detailed docs in `references/` directory
- ✅ **Bundled Resources**: Setup scripts included

## Publishing Methods

### Method 1: GitHub Repository (Recommended)

Since your skill is already on GitHub, this is the easiest approach:

#### 1. Ensure Repository is Public
```bash
# Check repository visibility
gh repo view --json visibility

# Make public if needed
gh repo edit --visibility public
```

#### 2. Add Skills.sh Topics/Tags
```bash
# Add topics for discoverability
gh repo edit --add-topic "skills-sh"
gh repo edit --add-topic "ai-agents" 
gh repo edit --add-topic "linear"
gh repo edit --add-topic "mcp"
gh repo edit --add-topic "project-management"
```

#### 3. Create a GitHub Release (Optional but Recommended)
```bash
# Tag the current version
git tag v1.0.0
git push origin v1.0.0

# Create a release
gh release create v1.0.0 \
  --title "Linear Skill v1.0.0" \
  --notes "Initial release of Linear MCP integration skill for AI agents"
```

#### 4. Test Installation
```bash
# Test installation from GitHub
npx skills add https://github.com/yourusername/linear-skill

# Or if published properly:
npx skills add linear-skill
```

### Method 2: NPM Package (Alternative)

If you want to distribute via npm:

#### 1. Create package.json
```json
{
  "name": "linear-skill",
  "version": "1.0.0", 
  "description": "Linear MCP integration skill for AI agents",
  "main": "SKILL.md",
  "files": [
    "SKILL.md",
    "scripts/**/*",
    "references/**/*"
  ],
  "keywords": [
    "skills-sh",
    "ai-agents", 
    "linear",
    "mcp",
    "project-management"
  ],
  "repository": {
    "type": "git",
    "url": "https://github.com/yourusername/linear-skill.git"
  },
  "license": "Apache-2.0"
}
```

#### 2. Publish to NPM
```bash
# Login to npm (first time only)
npm login

# Publish the package
npm publish
```

### Method 3: Self-Hosting with Well-Known URI

For complete control over distribution:

#### 1. Use SkillKit Publish Command
```bash
# Install skillkit (if available)
npm install -g skillkit

# Generate well-known URI structure
skillkit publish
```

#### 2. Host on Your Domain
The publish command generates an RFC 8615 well-known URI structure that you can host on your domain.

## Automatic Discovery

Once published through any method, your skill will automatically appear on skills.sh when:

1. **Installation Telemetry**: People use `npx skills add linear-skill`
2. **Usage Data**: The skill gets loaded and used by agents
3. **No Manual Submission**: Skills.sh automatically discovers popular skills

## Validation Before Publishing

Run these checks before publishing:

### 1. Structure Validation ✅
```bash
# Already passed - your structure is correct
ls -la  # Should show SKILL.md, scripts/, references/
```

### 2. YAML Frontmatter Validation ✅
```bash
# Already validated - your YAML is compliant
head -10 SKILL.md  # Should show proper YAML frontmatter
```

### 3. Functionality Testing
```bash
# Test your setup scripts
./scripts/setup-linear-mcp.sh --help
./scripts/setup-claude-mcp.sh --help

# Test validation
node scripts/validate-setup.js --help
node scripts/validate-claude-setup.js --help
```

### 4. Documentation Check
```bash
# Ensure all references work
grep -r "references/" SKILL.md README.md
grep -r "scripts/" SKILL.md README.md
```

## Publishing Checklist

Before going live:

- [ ] ✅ Repository is public on GitHub
- [ ] ✅ SKILL.md has valid YAML frontmatter  
- [ ] ✅ README.md explains skills.sh installation
- [ ] ✅ All scripts are executable and tested
- [ ] ✅ Documentation links work correctly
- [ ] ✅ License is specified (Apache-2.0)
- [ ] Add relevant GitHub topics/tags
- [ ] Create a GitHub release (recommended)
- [ ] Test installation command works

## Post-Publishing

### Monitor Discovery
Skills appear on skills.sh based on installation telemetry:

1. **Share Installation Command**: `npx skills add linear-skill`
2. **Monitor GitHub Analytics**: Track stars, forks, traffic
3. **Check Skills.sh**: Look for your skill in the directory

### Maintenance
- **Update Version**: Increment version in metadata when making changes
- **Create Releases**: Use semantic versioning for GitHub releases  
- **Respond to Issues**: Monitor GitHub issues for user feedback

## Example Installation Commands

Once published, users can install your skill via:

```bash
# Via skills.sh (after discovery)
npx skills add linear-skill

# Via GitHub directly
npx skills add https://github.com/yourusername/linear-skill

# Via npm (if published to npm)
npm install -g linear-skill
```

## Skills.sh Best Practices

### Description Optimization
Your description is already well-optimized, but ensure it:
- ✅ Mentions trigger phrases ("Linear", "project management", "task tracking")
- ✅ Explains when to use the skill
- ✅ Stays under 1024 characters (yours is 317 chars)

### Discoverability
- Use relevant keywords in repository topics
- Include clear usage examples in README.md
- Add screenshots or GIFs showing the skill in action (optional)

### Community Engagement
- Encourage users to star your repository
- Respond to issues and feature requests
- Consider creating a discussion forum or wiki

## Troubleshooting Publishing

### Common Issues

**"Skill not appearing on skills.sh"**
- Skills appear via installation telemetry, not immediately
- Ensure people are actually installing and using the skill
- Check that the GitHub repository is public

**"Installation fails"**
- Verify SKILL.md syntax and structure
- Test the repository URL directly
- Check that all referenced files exist

**"YAML frontmatter errors"**
- Validate YAML syntax online
- Ensure required fields (name, description) are present
- Check for special characters or encoding issues

## Support

If you encounter issues publishing to skills.sh:

1. **Check Skills.sh Documentation**: Visit [skills.sh/docs](https://skills.sh/docs)
2. **Validate Your Skill**: Use the checklist above
3. **Test Installation**: Try installing your own skill
4. **Community Help**: Engage with the skills.sh community

---

**Your Linear skill is ready for skills.sh!** The structure is compliant and all validation passes. Choose your preferred publishing method and make it available to the AI agent community.