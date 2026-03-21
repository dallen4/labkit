/**
 * Single source of truth for available patterns in labkit
 */

export enum Platform {
  Claude = 'claude',
  Cursor = 'cursor',
  Windsurf = 'windsurf',
  Copilot = 'copilot'
}

const allPlatforms = [Platform.Claude, Platform.Cursor, Platform.Windsurf, Platform.Copilot];

export interface Skill {
  name: string;
  description: string;
  platforms: Platform[];
}

export interface Command {
  name: string;
  description: string;
  platforms: Platform[];
}

export interface Rule {
  name: string;
  description: string;
  platforms: Platform[];
}

export const PLATFORMS: Record<Platform, { name: string; description: string }> = {
  [Platform.Claude]: {
    name: 'Claude Code',
    description: 'Full support: commands, skills, settings'
  },
  [Platform.Cursor]: {
    name: 'Cursor',
    description: 'Commands, skills, and rules'
  },
  [Platform.Windsurf]: {
    name: 'Windsurf',
    description: 'Skills and rules'
  },
  [Platform.Copilot]: {
    name: 'GitHub Copilot',
    description: 'Skills and instructions'
  }
};

export const SKILLS: Skill[] = [
  {
    name: 'playwright-cli',
    description: 'Browser automation for testing, screenshots, and data extraction',
    platforms: [Platform.Claude, Platform.Cursor, Platform.Windsurf, Platform.Copilot]
  },
  {
    name: 'it2',
    description: 'iTerm2 terminal control — manage sessions, windows, tabs, and broadcast input',
    platforms: [Platform.Claude, Platform.Cursor, Platform.Windsurf, Platform.Copilot]
  }
];

export const COMMANDS: Command[] = [
  {
    name: 'spawn',
    description: 'Create worktree + iTerm2 pane + agent',
    platforms: [Platform.Claude, Platform.Cursor]
  },
  {
    name: 'commit',
    description: 'Conventional commits from staged changes',
    platforms: [Platform.Claude, Platform.Cursor]
  },
  {
    name: 'create-pr',
    description: 'Structured PR creation',
    platforms: [Platform.Claude, Platform.Cursor]
  },
  {
    name: 'focus',
    description: 'Focus iTerm2 pane by branch',
    platforms: [Platform.Claude, Platform.Cursor]
  },
  {
    name: 'worktrees',
    description: 'List worktrees + sessions',
    platforms: [Platform.Claude, Platform.Cursor]
  },
  {
    name: 'teardown',
    description: 'Close pane + remove worktree',
    platforms: [Platform.Claude, Platform.Cursor]
  },
  {
    name: 'research',
    description: 'Parallel codebase + web investigation',
    platforms: [Platform.Claude, Platform.Cursor]
  }
];

export const RULES: Rule[] = [
  {
    name: 'commit-conventions',
    description: 'Conventional commit format and patterns',
    platforms: [Platform.Cursor, Platform.Windsurf]
  },
  {
    name: 'agentic-workflow',
    description: 'Multi-agent orchestration patterns',
    platforms: [Platform.Cursor, Platform.Windsurf]
  },
  {
    name: 'pr-workflow',
    description: 'PR creation and review conventions',
    platforms: [Platform.Cursor, Platform.Windsurf]
  }
];

/**
 * Get skills available for selected platforms
 */
export function getAvailableSkills(platforms: Platform[]): Skill[] {
  return SKILLS.filter(skill =>
    skill.platforms.some(p => platforms.includes(p))
  );
}

/**
 * Get commands available for selected platforms
 */
export function getAvailableCommands(platforms: Platform[]): Command[] {
  return COMMANDS.filter(command =>
    command.platforms.some(p => platforms.includes(p))
  );
}

/**
 * Get rules available for selected platforms
 */
export function getAvailableRules(platforms: Platform[]): Rule[] {
  return RULES.filter(rule =>
    rule.platforms.some(p => platforms.includes(p))
  );
}
