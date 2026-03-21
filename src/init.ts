import * as p from '@clack/prompts';
import { writeConfig, readConfig } from './config';
import { pullPatterns } from './tiged';
import {
  PLATFORMS,
  Platform,
  getAvailableSkills,
  getAvailableCommands,
  getAvailableRules
} from './manifest';

export async function init(): Promise<void> {
  console.clear();

  p.intro('labkit — build your own toolkit');

  // Check if config already exists
  const existing = await readConfig();
  if (existing) {
    const shouldContinue = await p.confirm({
      message: '.labkitrc already exists. Overwrite?',
      initialValue: false
    });

    if (p.isCancel(shouldContinue) || !shouldContinue) {
      p.cancel('Operation cancelled');
      process.exit(0);
    }
  }

  // Source repo
  const source = await p.text({
    message: 'Source repo?',
    placeholder: 'dallen4/labkit',
    initialValue: 'dallen4/labkit',
    validate: (value) => {
      if (!value || !value.includes('/')) {
        return 'Must be in format: username/repo';
      }
    }
  });

  if (p.isCancel(source)) {
    p.cancel('Operation cancelled');
    process.exit(0);
  }

  // Platforms
  const platforms = await p.multiselect({
    message: 'Which platforms do you use?',
    options: Object.entries(PLATFORMS).map(([key, { name, description }]) => ({
      value: key as Platform,
      label: name,
      hint: description
    })),
    required: true
  });

  if (p.isCancel(platforms) || platforms.length === 0) {
    p.cancel('Operation cancelled');
    process.exit(0);
  }

  const selectedPlatforms = platforms as Platform[];

  // Skills
  const availableSkills = getAvailableSkills(selectedPlatforms);
  let selectedSkills: string[] = [];

  if (availableSkills.length > 0) {
    const platformNames = selectedPlatforms.map(p => PLATFORMS[p].name).join(', ');

    const skills = await p.multiselect({
      message: `Which skills? (available for: ${platformNames})`,
      options: availableSkills.map(skill => ({
        value: skill.name,
        label: skill.name,
        hint: skill.description
      }))
    });

    if (!p.isCancel(skills)) {
      selectedSkills = skills as string[];
    }
  }

  // Commands
  const availableCommands = getAvailableCommands(selectedPlatforms);
  let selectedCommands: string[] = [];

  if (availableCommands.length > 0) {
    const platformNames = selectedPlatforms
      .filter(p => [Platform.Claude, Platform.Cursor].includes(p))
      .map(p => PLATFORMS[p].name)
      .join(', ');

    const commands = await p.multiselect({
      message: `Which commands? (available for: ${platformNames})`,
      options: availableCommands.map(cmd => ({
        value: cmd.name,
        label: cmd.name,
        hint: cmd.description
      }))
    });

    if (!p.isCancel(commands)) {
      selectedCommands = commands as string[];
    }
  }

  // Rules
  const availableRules = getAvailableRules(selectedPlatforms);
  let selectedRules: string[] = [];

  if (availableRules.length > 0) {
    const platformNames = selectedPlatforms
      .filter(p => [Platform.Cursor, Platform.Windsurf].includes(p))
      .map(p => PLATFORMS[p].name)
      .join(', ');

    const rules = await p.multiselect({
      message: `Which rules? (available for: ${platformNames})`,
      options: availableRules.map(rule => ({
        value: rule.name,
        label: rule.name,
        hint: rule.description
      }))
    });

    if (!p.isCancel(rules)) {
      selectedRules = rules as string[];
    }
  }

  // Build config
  const config = {
    source: source as string,
    platforms: selectedPlatforms,
    skills: selectedSkills,
    commands: selectedCommands,
    rules: selectedRules
  };

  // Write config
  const s = p.spinner();
  s.start('Writing .labkitrc');
  await writeConfig(config);
  s.stop('Written .labkitrc');

  // Pull patterns
  s.start(`Pulling for ${selectedPlatforms.length} platform(s)...`);
  try {
    const copied = await pullPatterns(config);
    s.stop('Patterns pulled successfully');

    // Show what was copied
    if (copied.length > 0) {
      p.log.message('Installed:');
      for (const item of copied) {
        p.log.success(`  ✓ ${item}`);
      }
    }

    // Hydration reminder
    if (selectedSkills.length > 0) {
      p.note(
        'Skills installed. Run hydration to set up external dependencies:\n  scripts/hydrate.sh',
        'Next steps'
      );
    }

    p.outro('Done! Run `labkit sync` anytime to update.');
  } catch (error) {
    s.stop('Failed to pull patterns');
    p.log.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}
