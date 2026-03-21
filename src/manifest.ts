/**
 * Single source of truth for available patterns in labkit
 */

export type Platform = 'claude' | 'cursor' | 'windsurf' | 'copilot';

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
  claude: {
    name: 'Claude Code',
    description: 'Full support: commands, skills, settings'
  },
  cursor: {
    name: 'Cursor',
    description: 'Commands, skills, and rules'
  },
  windsurf: {
    name: 'Windsurf',
    description: 'Skills and rules'
  },
  copilot: {
    name: 'GitHub Copilot',
    description: 'Skills and instructions'
  }
};

export const SKILLS: Skill[] = [
  {
    name: 'playwright-cli',
    description: 'Browser automation for testing, screenshots, and data extraction',
    platforms: ['claude', 'cursor', 'windsurf', 'copilot']
  },
  {
    name: 'it2',
    description: 'iTerm2 terminal control — manage sessions, windows, tabs, and broadcast input',
    platforms: ['claude', 'cursor', 'windsurf', 'copilot']
  }
];

export const COMMANDS: Command[] = [
  {
    name: 'spawn',
    description: 'Create worktree + iTerm2 pane + agent',
    platforms: ['claude', 'cursor']
  },
  {
    name: 'commit',
    description: 'Conventional commits from staged changes',
    platforms: ['claude', 'cursor']
  },
  {
    name: 'create-pr',
    description: 'Structured PR creation',
    platforms: ['claude', 'cursor']
  },
  {
    name: 'focus',
    description: 'Focus iTerm2 pane by branch',
    platforms: ['claude', 'cursor']
  },
  {
    name: 'worktrees',
    description: 'List worktrees + sessions',
    platforms: ['claude', 'cursor']
  },
  {
    name: 'teardown',
    description: 'Close pane + remove worktree',
    platforms: ['claude', 'cursor']
  },
  {
    name: 'research',
    description: 'Parallel codebase + web investigation',
    platforms: ['claude', 'cursor']
  }
];

export const RULES: Rule[] = [
  {
    name: 'commit-conventions',
    description: 'Conventional commit format and patterns',
    platforms: ['cursor', 'windsurf']
  },
  {
    name: 'agentic-workflow',
    description: 'Multi-agent orchestration patterns',
    platforms: ['cursor', 'windsurf']
  },
  {
    name: 'pr-workflow',
    description: 'PR creation and review conventions',
    platforms: ['cursor', 'windsurf']
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
