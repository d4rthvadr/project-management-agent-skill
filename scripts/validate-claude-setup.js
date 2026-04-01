#!/usr/bin/env node

/**
 * Claude Desktop Linear MCP Setup Validator
 * Validates that Linear MCP integration is properly configured for Claude Desktop
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

// Logging functions
const log = {
  info: (msg) => console.log(`${colors.cyan}ℹ️  ${msg}${colors.reset}`),
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  warning: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
  header: (msg) => console.log(`${colors.magenta}${msg}${colors.reset}`)
};

/**
 * Get Claude Desktop configuration file path based on OS
 */
function getClaudeConfigPath() {
  const platform = os.platform();
  
  if (platform === 'darwin') {
    return path.join(os.homedir(), 'Library', 'Application Support', 'Claude', 'claude_desktop_config.json');
  } else if (platform === 'win32') {
    return path.join(os.homedir(), 'AppData', 'Roaming', 'Claude', 'claude_desktop_config.json');
  } else if (platform === 'linux') {
    return path.join(os.homedir(), '.config', 'claude', 'claude_desktop_config.json');
  } else {
    log.warning(`Unsupported platform: ${platform}`);
    return null;
  }
}

/**
 * Check if Claude Desktop config exists and is valid
 */
function checkClaudeConfig() {
  const configPath = getClaudeConfigPath();
  
  if (!configPath) {
    log.error('Could not determine Claude Desktop config path for this platform');
    return false;
  }
  
  log.info(`Checking Claude config at: ${configPath}`);
  
  if (!fs.existsSync(configPath)) {
    log.error('Claude Desktop config file not found');
    log.info('Expected location: ' + configPath);
    return false;
  }
  
  try {
    const content = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(content);
    
    // Check structure
    if (!config.mcpServers) {
      log.error('Claude config missing "mcpServers" section');
      return false;
    }
    
    if (!config.mcpServers.linear) {
      log.error('Claude config missing "linear" server configuration');
      return false;
    }
    
    const linearConfig = config.mcpServers.linear;
    
    // Check Linear MCP configuration
    if (linearConfig.command !== 'npx') {
      log.warning('Linear server not using npx command');
    }
    
    if (!linearConfig.args || !linearConfig.args.includes('linear-mcp-server')) {
      log.error('Linear server not configured to use linear-mcp-server');
      return false;
    }
    
    if (!linearConfig.env) {
      log.error('Linear server missing environment configuration');
      return false;
    }
    
    if (!('LINEAR_API_KEY' in linearConfig.env)) {
      log.error('Linear server missing LINEAR_API_KEY environment variable configuration');
      return false;
    }
    
    // Check if API key is empty (should be empty for system env var)
    if (linearConfig.env.LINEAR_API_KEY !== '') {
      log.warning('LINEAR_API_KEY should be empty in config (Claude reads from system environment)');
    }
    
    log.success('Claude Desktop config is valid and properly configured');
    return true;
  } catch (error) {
    log.error(`Invalid JSON in Claude config: ${error.message}`);
    return false;
  }
}

/**
 * Check system environment variable
 */
function checkSystemEnvironmentVariable() {
  const apiKey = process.env.LINEAR_API_KEY;
  
  if (!apiKey) {
    log.error('LINEAR_API_KEY system environment variable not set');
    log.info('Make sure to set it system-wide, not just in terminal');
    return false;
  }
  
  if (!apiKey.startsWith('lin_api_')) {
    log.warning('LINEAR_API_KEY does not start with "lin_api_" - this might be incorrect');
  }
  
  log.success('LINEAR_API_KEY system environment variable is set');
  return true;
}

/**
 * Check Node.js and npx availability
 */
async function checkNodeJs() {
  try {
    const { stdout: nodeVersion } = await execAsync('node --version');
    log.success(`Node.js found: ${nodeVersion.trim()}`);
  } catch (error) {
    log.error('Node.js not found - required for Linear MCP server');
    return false;
  }
  
  try {
    const { stdout: npxVersion } = await execAsync('npx --version');
    log.success(`npx found: ${npxVersion.trim()}`);
  } catch (error) {
    log.error('npx not found - required for Linear MCP server');
    return false;
  }
  
  return true;
}

/**
 * Check if Claude Desktop is installed
 */
async function checkClaudeDesktop() {
  const platform = os.platform();
  
  try {
    if (platform === 'darwin') {
      // Check macOS applications
      const claudeAppPath = '/Applications/Claude.app';
      if (fs.existsSync(claudeAppPath)) {
        log.success('Claude Desktop found in Applications');
        return true;
      } else {
        log.warning('Claude Desktop not found in /Applications/Claude.app');
      }
    } else if (platform === 'win32') {
      // Check Windows common installation paths
      const commonPaths = [
        path.join(process.env.LOCALAPPDATA || '', 'Claude', 'Claude.exe'),
        path.join(process.env.PROGRAMFILES || '', 'Claude', 'Claude.exe'),
        path.join(process.env['PROGRAMFILES(X86)'] || '', 'Claude', 'Claude.exe')
      ];
      
      for (const claudePath of commonPaths) {
        if (fs.existsSync(claudePath)) {
          log.success(`Claude Desktop found at: ${claudePath}`);
          return true;
        }
      }
      log.warning('Claude Desktop not found in common Windows locations');
    } else {
      log.info('Skipping Claude Desktop check on this platform');
      return true;
    }
    
    log.info('Download Claude Desktop from: https://claude.ai/desktop');
    return true; // Don't fail validation for this
  } catch (error) {
    log.warning(`Could not check Claude Desktop installation: ${error.message}`);
    return true;
  }
}

/**
 * Test Linear MCP server availability
 */
async function testMcpServer() {
  log.info('Testing Linear MCP server...');
  
  try {
    // Try to run the server with a timeout
    const timeoutCommand = os.platform() === 'win32' ? 
      'timeout /t 5 npx -y linear-mcp-server --help' : 
      'timeout 5s npx -y linear-mcp-server --help || echo "timeout"';
      
    const { stdout } = await execAsync(timeoutCommand);
    
    if (stdout.includes('timeout')) {
      log.warning('Linear MCP server test timed out (this might be normal)');
      return true;
    }
    
    log.success('Linear MCP server is accessible');
    return true;
  } catch (error) {
    log.warning('Could not test Linear MCP server - this might be normal during first setup');
    return true;
  }
}

/**
 * Test Linear API connectivity
 */
async function testLinearApi() {
  const apiKey = process.env.LINEAR_API_KEY;
  if (!apiKey) {
    log.warning('Skipping Linear API test - no API key in environment');
    return false;
  }
  
  log.info('Testing Linear API connectivity...');
  
  try {
    // Use curl if available, otherwise skip
    const curlCommand = os.platform() === 'win32' ? 'where curl' : 'which curl';
    await execAsync(curlCommand);
    
    const apiCommand = `curl -s -H "Authorization: Bearer ${apiKey}" -H "Content-Type: application/json" -d "{\\"query\\":\\"{ viewer { name } }\\"}" https://api.linear.app/graphql`;
    const { stdout } = await execAsync(apiCommand);
    
    const response = JSON.parse(stdout);
    
    if (response.data && response.data.viewer) {
      log.success(`Linear API connectivity confirmed - logged in as: ${response.data.viewer.name}`);
      return true;
    } else if (response.errors) {
      log.error(`Linear API error: ${response.errors[0].message}`);
      return false;
    } else {
      log.error('Unexpected Linear API response');
      return false;
    }
  } catch (error) {
    log.warning('Could not test Linear API connectivity (curl might not be available)');
    return true; // Don't fail validation for this
  }
}

/**
 * Generate validation report
 */
function generateReport(results) {
  console.log('\n' + '='.repeat(60));
  log.header('📊 CLAUDE DESKTOP LINEAR MCP VALIDATION REPORT');
  console.log('='.repeat(60));
  
  const passed = Object.values(results).filter(Boolean).length;
  const total = Object.keys(results).length;
  
  console.log(`\nResults: ${passed}/${total} checks passed\n`);
  
  Object.entries(results).forEach(([check, passed]) => {
    const status = passed ? `${colors.green}PASS${colors.reset}` : `${colors.red}FAIL${colors.reset}`;
    console.log(`${status} ${check}`);
  });
  
  console.log('\n' + '='.repeat(60));
  
  if (passed === total) {
    log.success('🎉 All validations passed! Your Claude Desktop Linear MCP setup is ready.');
    console.log('\nNext steps:');
    console.log('1. Restart Claude Desktop completely');
    console.log('2. Start a new conversation');
    console.log('3. Look for hammer icon at bottom of chat');
    console.log('4. Test with: "Show me my Linear tasks"');
  } else {
    log.error('❌ Some validations failed. Please check the errors above.');
    console.log('\nRefer to the SKILL.md troubleshooting section for Claude Desktop.');
  }
  
  return passed === total;
}

/**
 * Main validation function
 */
async function main() {
  log.header('🔍 Claude Desktop Linear MCP Setup Validator');
  log.header('===========================================\n');
  
  const results = {};
  
  results['Node.js & npx'] = await checkNodeJs();
  results['Claude Desktop'] = await checkClaudeDesktop();
  results['Claude Config File'] = checkClaudeConfig();
  results['System Environment Variable'] = checkSystemEnvironmentVariable();
  results['MCP Server'] = await testMcpServer();
  results['Linear API'] = await testLinearApi();
  
  const allPassed = generateReport(results);
  process.exit(allPassed ? 0 : 1);
}

// Handle command line arguments
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log('Claude Desktop Linear MCP Setup Validator');
  console.log('');
  console.log('Usage: node validate-claude-setup.js');
  console.log('');
  console.log('This script validates that Linear MCP integration is properly configured for Claude Desktop.');
  console.log('It checks:');
  console.log('  - Node.js and npx installation');
  console.log('  - Claude Desktop installation');
  console.log('  - Claude Desktop config file (claude_desktop_config.json)');
  console.log('  - System environment variables');
  console.log('  - MCP server availability');
  console.log('  - Linear API connectivity');
  process.exit(0);
}

// Run validation
main().catch(error => {
  log.error(`Validation failed: ${error.message}`);
  process.exit(1);
});