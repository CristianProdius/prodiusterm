/**
 * Workspace Configuration
 *
 * Reads .workspace.json from a project root to auto-setup the terminal layout.
 * When a project is opened, this config drives:
 * - Dev server pane (runs the configured command)
 * - Worktree panes (creates git worktrees, launches Claude Code in each)
 * - Extra tool panes (test watchers, log tails, etc.)
 */

import fs from "fs";
import path from "path";

export interface WorkspaceWorktreeConfig {
  name: string;
  branch: string;
}

export interface WorkspaceExtraConfig {
  name: string;
  command: string;
}

export interface WorkspaceServerConfig {
  command: string;
}

export interface WorkspaceConfig {
  server?: WorkspaceServerConfig;
  worktrees?: WorkspaceWorktreeConfig[];
  extras?: WorkspaceExtraConfig[];
}

const WORKSPACE_CONFIG_FILE = ".workspace.json";

/**
 * Resolve ~ to home directory
 */
function resolvePath(p: string): string {
  return p.replace(/^~/, process.env.HOME || "~");
}

/**
 * Read .workspace.json from a project directory
 */
export function readWorkspaceConfig(
  projectDir: string
): WorkspaceConfig | null {
  const resolvedDir = resolvePath(projectDir);
  const configPath = path.join(resolvedDir, WORKSPACE_CONFIG_FILE);

  if (!fs.existsSync(configPath)) {
    return null;
  }

  try {
    const raw = fs.readFileSync(configPath, "utf-8");
    const config = JSON.parse(raw) as WorkspaceConfig;
    return validateWorkspaceConfig(config);
  } catch (error) {
    console.error(`Failed to read workspace config from ${configPath}:`, error);
    return null;
  }
}

/**
 * Validate and sanitize a workspace config
 */
function validateWorkspaceConfig(
  config: WorkspaceConfig
): WorkspaceConfig | null {
  if (!config || typeof config !== "object") {
    return null;
  }

  const result: WorkspaceConfig = {};

  if (config.server && typeof config.server.command === "string") {
    result.server = { command: config.server.command };
  }

  if (Array.isArray(config.worktrees)) {
    result.worktrees = config.worktrees.filter(
      (wt) =>
        typeof wt === "object" &&
        typeof wt.name === "string" &&
        typeof wt.branch === "string"
    );
  }

  if (Array.isArray(config.extras)) {
    result.extras = config.extras.filter(
      (ex) =>
        typeof ex === "object" &&
        typeof ex.name === "string" &&
        typeof ex.command === "string"
    );
  }

  return result;
}

/**
 * Write a .workspace.json template to a project directory
 */
export function writeWorkspaceTemplate(projectDir: string): string {
  const resolvedDir = resolvePath(projectDir);
  const configPath = path.join(resolvedDir, WORKSPACE_CONFIG_FILE);

  const template: WorkspaceConfig = {
    server: { command: "pnpm dev" },
    worktrees: [
      { name: "feature-1", branch: "feat/feature-1" },
      { name: "feature-2", branch: "feat/feature-2" },
    ],
    extras: [{ name: "tests", command: "pnpm test:watch" }],
  };

  fs.writeFileSync(configPath, JSON.stringify(template, null, 2) + "\n");
  return configPath;
}
