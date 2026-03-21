import * as p from '@clack/prompts';
import { readConfig } from './config';
import { pullPatterns } from './tiged';

export async function sync(): Promise<void> {
  const s = p.spinner();

  // Read config
  s.start('Reading .labkitrc');
  const config = await readConfig();

  if (!config) {
    s.stop('.labkitrc not found');
    p.log.error('No .labkitrc found. Run `labkit init` first.');
    process.exit(1);
  }

  s.stop('Config loaded');

  // Pull latest patterns
  s.start(`Syncing from ${config.source}...`);

  try {
    const copied = await pullPatterns(config);
    s.stop('Sync complete');

    // Show what was updated
    if (copied.length > 0) {
      p.log.message('Updated:');
      for (const item of copied) {
        p.log.success(`  ✓ ${item}`);
      }
    } else {
      p.log.warn('No patterns found to sync');
    }

    // Hydration reminder
    if (config.skills.length > 0) {
      p.note(
        'Run hydration to ensure external dependencies are up to date:\n  scripts/hydrate.sh',
        'Reminder'
      );
    }

    p.outro('Done!');
  } catch (error) {
    s.stop('Sync failed');
    p.log.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}
