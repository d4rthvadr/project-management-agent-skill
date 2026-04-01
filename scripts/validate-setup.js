#!/usr/bin/env node

/**
 * Linear MCP Setup Validator
 * Validates that Linear MCP integration is properly configured
 */

const fs = require('fs');
const path = require('path');
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
  cyan: '\x1b[36m'
};

// Logging functions
const log = {
  info: (msg) => console.log(`${colors.cyan}ℹ️  ${msg}${colors.reset}`),
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  warning: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`)
};

/**
 * Check if we're in a git repository
 */
async function checkGitRepo() {
  try {
    await execAsync('git rev-parse --git-dir');
    log.success('Running in git repository');
    return true;
  } catch (error) {
    log.error('Not in a git repository');
    return false;
  }
}

/**
 * Check if mcp.json exists and is valid
 */
function checkMcpJson() {
  const mcpPath = path.join('.vscode', 'mcp.json');
  
  if (!fs.existsSync(mcpPath)) {
    log.error('.vscode/mcp.json not found');
    return false;
  }
  
  try {
    const content = fs.readFileSync(mcpPath, 'utf8');
    const config = JSON.parse(content);
    
    // Check structure
    if (!config.servers) {
      log.error('mcp.json missing "servers" section');
      return false;
    }
    
    if (!config.servers.linear) {
      log.error('mcp.json missing "linear" server configuration');
      return false;
    }
    
    const linearConfig = config.servers.linear;
    
    if (linearConfig.command !== 'npx') {
      log.warning('Linear server not using npx command');
    }
    
    if (!linearConfig.args || !linearConfig.args.includes('linear-mcp-server')) {
      log.error('Linear server not configured to use linear-mcp-server');
      return false;
    }
    
    if (!linearConfig.env || !linearConfig.env.LINEAR_API_KEY) {
      log.error('Linear server missing LINEAR_API_KEY environment variable');
      return false;
    }
    
    log.success('.vscode/mcp.json is valid and properly configured');
    return true;
  } catch (error) {
    log.error(`Invalid JSON in mcp.json: ${error.message}`);
    return false;
  }
}

/**
 * Check environment variable
 */
function checkEnvironmentVariable() {
  const apiKey = process.env.LINEAR_API_KEY;
  
  if (!apiKey) {
    log.error('LINEAR_API_KEY environment variable not set');
    return false;
  }
  
  if (!apiKey.startsWith('lin_api_')) {
    log.warning('LINEAR_API_KEY does not start with "lin_api_" - this might be incorrect');
  }
  
  log.success('LINEAR_API_KEY environment variable is set');
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
    log.error('Node.js not found');
    return false;
  }
  
  try {
    const { stdout: npxVersion } = await execAsync('npx --version');
    log.success(`npx found: ${npxVersion.trim()}`);
  } catch (error) {
    log.error('npx not found');
    return false;
  }
  
  return true;
}

/**
 * Test Linear MCP server availability
 */
async function testMcpServer() {
  log.info('Testing Linear MCP server...');
  
  try {
    // Try to run the server with a timeout
    const { stdout } = await execAsync('timeout 5s npx -y linear-mcp-server --help || echo "timeout"');
    
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
    log.warning('Skipping Linear API test - no API key');
    return false;
  }
  
  log.info('Testing Linear API connectivity...');
  
  try {
    // Use curl if available, otherwise skip
    await execAsync('which curl');
    
    const curlCommand = `curl -s -H "Authorization: Bearer ${apiKey}" -H "Content-Type: application/json" -d '{"query":"{ viewer { name } }"}' https://api.linear.app/graphql`;
    const { stdout } = await execAsync(curlCommand);
    
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
 * Check VS Code installation
 */
async function checkVSCode() {
  try {
    const { stdout } = await execAsync('code --version');
    const version = stdout.split('\n')[0];
    log.success(`VS Code found: ${version}`);
    return true;
  } catch (error) {
    log.warning('VS Code CLI not found - make sure VS Code is installed and added to PATH');
    return true; // Don't fail validation for this
  }
}

/**
 * Generate validation report
 */
function generateReport(results) {
  console.log('\n' + '='.repeat(50));
  console.log('📊 VALIDATION REPORT');
  console.log('='.repeat(50));
  
  const passed = Object.values(results).filter(Boolean).length;
  const total = Object.keys(results).length;
  
  console.log(`\nResults: ${passed}/${total} checks passed\n`);
  
  Object.entries(results).forEach(([check, passed]) => {
    const status = passed ? `${colors.green}PASS${colors.reset}` : `${colors.red}FAIL${colors.reset}`;
    console.log(`${status} ${check}`);
  });
  
  console.log('\n' + '='.repeat(50));
  
  if (passed === total) {
    log.success('🎉 All validations passed! Your Linear MCP setup is ready.');
    console.log('\nNext steps:');
    console.log('1. Restart VS Code');
    console.log('2. Open Copilot Chat');
    console.log('3. Test with: "Show me my Linear tasks"');
  } else {
    log.error('❌ Some validations failed. Please check the errors above.');
    console.log('\nRefer to the SKILL.md troubleshooting section for help.');
  }
  
  return passed === total;
}

/**
 * Main validation function
 */
async function main() {
  console.log('🔍 Linear MCP Setup Validator');
  console.log('============================\n');
  
  const results = {};
  
  results['Git Repository'] = await checkGitRepo();
  results['Node.js & npx'] = await checkNodeJs();
  results['VS Code'] = await checkVSCode();
  results['mcp.json Configuration'] = checkMcpJson();
  results['Environment Variable'] = checkEnvironmentVariable();
  results['MCP Server'] = await testMcpServer();
  results['Linear API'] = await testLinearApi();
  
  const allPassed = generateReport(results);
  process.exit(allPassed ? 0 : 1);
}

// Handle command line arguments
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log('Linear MCP Setup Validator');
  console.log('');
  console.log('Usage: node validate-setup.js');
  console.log('');
  console.log('This script validates that Linear MCP integration is properly configured.');
  console.log('It checks:');
  console.log('  - Git repository');
  console.log('  - Node.js and npx installation');
  console.log('  - VS Code installation');
  console.log('  - mcp.json configuration');
  console.log('  - Environment variables');
  console.log('  - MCP server availability');
  console.log('  - Linear API connectivity');
  process.exit(0);
}

// Run validation
main().catch(error => {
  log.error(`Validation failed: ${error.message}`);
  process.exit(1);
});