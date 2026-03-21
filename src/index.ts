#!/usr/bin/env node

import { init } from './init';
import { sync } from './sync';

const args = process.argv.slice(2);
const command = args[0];

async function main() {
  switch (command) {
    case 'init':
      await init();
      break;

    case 'sync':
      await sync();
      break;

    case '--help':
    case '-h':
    case 'help':
      showHelp();
      break;

    case '--version':
    case '-v':
      showVersion();
      break;

    default:
      console.error(`Unknown command: ${command || '(none)'}`);
      console.error('');
      showHelp();
      process.exit(1);
  }
}

function showHelp() {
  console.log(`
labkit — reusable kit of agentic patterns for AI coding assistants

Usage:
  labkit init    Interactive setup — choose platforms, skills, commands, and rules
  labkit sync    Pull latest versions of everything in .labkitrc
  labkit help    Show this help message

Examples:
  npx labkit init              # Start interactive setup
  npx labkit sync              # Update all patterns from source

Learn more: https://github.com/dallen4/labkit
  `);
}

function showVersion() {
  // Read version from package.json
  import('../package.json', { with: { type: 'json' } }).then(pkg => {
    console.log(pkg.default.version);
  });
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
