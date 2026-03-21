import { cosmiconfig } from 'cosmiconfig';
import { writeFile } from 'fs/promises';
import { dump, load } from 'js-yaml';
import type { Platform } from './manifest';

export interface LabkitConfig {
  source: string;
  platforms: Platform[];
  skills: string[];
  commands: string[];
  rules: string[];
}

const explorer = cosmiconfig('labkit', {
  searchPlaces: [
    '.labkitrc',
    '.labkitrc.yaml',
    '.labkitrc.yml',
    '.labkitrc.json',
    'labkit.config.js'
  ]
});

/**
 * Read .labkitrc from the current directory
 */
export async function readConfig(): Promise<LabkitConfig | null> {
  try {
    const result = await explorer.search();
    return result?.config || null;
  } catch (error) {
    return null;
  }
}

/**
 * Write .labkitrc to the current directory
 */
export async function writeConfig(config: LabkitConfig): Promise<void> {
  const yaml = dump(config, {
    indent: 2,
    lineWidth: 80,
    noRefs: true
  });

  await writeFile('.labkitrc', yaml, 'utf-8');
}

/**
 * Parse YAML config from string (used by shell script)
 */
export function parseConfig(yaml: string): LabkitConfig {
  return load(yaml) as LabkitConfig;
}

/**
 * Default config
 */
export function getDefaultConfig(): Partial<LabkitConfig> {
  return {
    source: 'dallen4/labkit',
    platforms: [],
    skills: [],
    commands: [],
    rules: []
  };
}
