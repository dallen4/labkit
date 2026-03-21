import tiged from 'tiged';
import { exec } from 'child_process';
import { promisify } from 'util';
import { rm, mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import type { LabkitConfig } from './config';
import { Platform } from './manifest';

const execAsync = promisify(exec);

const STAGE_DIR = '.labkit-tmp';

/**
 * Pull patterns from GitHub using tiged + cpx strategy
 */
export async function pullPatterns(config: LabkitConfig): Promise<string[]> {
  const results: string[] = [];

  try {
    // Step 1: Stage — fetch relevant directories with tiged
    await stageDirectories(config.source, config.platforms);

    // Step 2: Copy — selectively copy files with cpx
    const copied = await copyPatterns(config);
    results.push(...copied);

    // Step 3: Clean up staging directory
    await cleanup();

    return results;
  } catch (error) {
    // Clean up on error
    await cleanup();
    throw error;
  }
}

/**
 * Stage directories from source repo
 */
async function stageDirectories(source: string, platforms: Platform[]): Promise<void> {
  // Create staging directory
  await mkdir(STAGE_DIR, { recursive: true });

  // Fetch platform directories
  const stagingTasks: Promise<void>[] = [];

  // Always fetch .claude for cross-compat skills
  stagingTasks.push(
    tiged(`${source}/.claude`, { force: true, verbose: false })
      .clone(`${STAGE_DIR}/.claude`)
  );

  // Fetch platform-specific directories
  if (platforms.includes(Platform.Cursor)) {
    stagingTasks.push(
      tiged(`${source}/.cursor`, { force: true, verbose: false })
        .clone(`${STAGE_DIR}/.cursor`)
    );
  }

  if (platforms.includes(Platform.Windsurf)) {
    stagingTasks.push(
      tiged(`${source}/.windsurf`, { force: true, verbose: false })
        .clone(`${STAGE_DIR}/.windsurf`)
    );
  }

  if (platforms.includes(Platform.Copilot)) {
    stagingTasks.push(
      tiged(`${source}/.github`, { force: true, verbose: false })
        .clone(`${STAGE_DIR}/.github`)
    );
  }

  // Also fetch scripts for hydration
  stagingTasks.push(
    tiged(`${source}/scripts`, { force: true, verbose: false })
      .clone(`${STAGE_DIR}/scripts`)
  );

  await Promise.all(stagingTasks);
}

/**
 * Copy patterns from staging to target locations
 */
async function copyPatterns(config: LabkitConfig): Promise<string[]> {
  const copied: string[] = [];

  // Skills → copy to all platform-specific directories for redundancy
  // All platforms support SKILL.md, so we install to each platform's native directory
  if (config.skills.length > 0) {
    const skillDirs: Record<Platform, string> = {
      [Platform.Claude]: '.claude/skills',
      [Platform.Cursor]: '.cursor/skills',
      [Platform.Windsurf]: '.windsurf/skills',
      [Platform.Copilot]: '.github/skills'
    };

    for (const platform of config.platforms) {
      const platformSkillsDir = skillDirs[platform];
      if (!platformSkillsDir) continue;

      await mkdir(platformSkillsDir, { recursive: true });

      for (const skill of config.skills) {
        const src = `${STAGE_DIR}/.claude/skills/${skill}`;
        const dest = `${platformSkillsDir}/${skill}`;

        if (existsSync(src)) {
          await cpx(`${src}/**/*`, dest);
          copied.push(dest);
        }
      }
    }
  }

  // Commands → per-platform
  if (config.platforms.includes(Platform.Claude) && config.commands.length > 0) {
    await mkdir('.claude/commands', { recursive: true });
    for (const cmd of config.commands) {
      const src = `${STAGE_DIR}/.claude/commands/${cmd}.md`;
      const dest = `.claude/commands/${cmd}.md`;

      if (existsSync(src)) {
        await cpx(src, dest);
        copied.push(dest);
      }
    }
  }

  if (config.platforms.includes(Platform.Cursor) && config.commands.length > 0) {
    await mkdir('.cursor/commands', { recursive: true });
    for (const cmd of config.commands) {
      const src = `${STAGE_DIR}/.cursor/commands/${cmd}.md`;
      const dest = `.cursor/commands/${cmd}.md`;

      if (existsSync(src)) {
        await cpx(src, dest);
        copied.push(dest);
      }
    }
  }

  // Rules → per-platform
  if (config.platforms.includes(Platform.Cursor) && config.rules.length > 0) {
    await mkdir('.cursor/rules', { recursive: true });
    for (const rule of config.rules) {
      const src = `${STAGE_DIR}/.cursor/rules/${rule}.mdc`;
      const dest = `.cursor/rules/${rule}.mdc`;

      if (existsSync(src)) {
        await cpx(src, dest);
        copied.push(dest);
      }
    }
  }

  if (config.platforms.includes(Platform.Windsurf) && config.rules.length > 0) {
    await mkdir('.windsurf/rules', { recursive: true });
    for (const rule of config.rules) {
      const src = `${STAGE_DIR}/.windsurf/rules/${rule}.md`;
      const dest = `.windsurf/rules/${rule}.md`;

      if (existsSync(src)) {
        await cpx(src, dest);
        copied.push(dest);
      }
    }
  }

  if (config.platforms.includes(Platform.Copilot)) {
    await mkdir('.github', { recursive: true });
    const src = `${STAGE_DIR}/.github/copilot-instructions.md`;
    const dest = `.github/copilot-instructions.md`;

    if (existsSync(src)) {
      await cpx(src, dest);
      copied.push(dest);
    }
  }

  // Copy hydration scripts
  const scriptsSrc = `${STAGE_DIR}/scripts`;
  if (existsSync(scriptsSrc)) {
    await cpx(`${scriptsSrc}/**/*`, 'scripts');
    copied.push('scripts/');
  }

  return copied;
}

/**
 * Cross-platform copy using cpx2
 */
async function cpx(source: string, dest: string): Promise<void> {
  await execAsync(`npx cpx2 "${source}" "${dest}"`);
}

/**
 * Clean up staging directory
 */
async function cleanup(): Promise<void> {
  if (existsSync(STAGE_DIR)) {
    await rm(STAGE_DIR, { recursive: true, force: true });
  }
}
