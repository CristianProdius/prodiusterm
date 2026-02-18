import { NextRequest, NextResponse } from "next/server";
import { readWorkspaceConfig } from "@/lib/workspace-config";
import {
  createWorktree,
  listWorktrees,
  type WorktreeInfo,
} from "@/lib/worktrees";
import { isGitRepo, branchExists } from "@/lib/git";

export interface WorkspacePaneCommand {
  role: "server" | "worktree" | "extra" | "shell";
  name: string;
  command: string;
  cwd: string;
}

/**
 * POST /api/workspace/setup
 * Parse .workspace.json, create missing worktrees, return pane commands
 */
export async function POST(request: NextRequest) {
  try {
    const { projectDir } = await request.json();
    if (!projectDir) {
      return NextResponse.json(
        { error: "projectDir is required" },
        { status: 400 }
      );
    }

    const config = readWorkspaceConfig(projectDir);
    if (!config) {
      return NextResponse.json(
        { error: "No .workspace.json found in project directory" },
        { status: 404 }
      );
    }

    const panes: WorkspacePaneCommand[] = [];
    const errors: string[] = [];

    // 1. Server pane
    if (config.server?.command) {
      panes.push({
        role: "server",
        name: "Dev Server",
        command: config.server.command,
        cwd: projectDir,
      });
    }

    // 2. Worktree panes
    if (config.worktrees && config.worktrees.length > 0) {
      const resolvedDir = projectDir.replace(/^~/, process.env.HOME || "~");
      const isRepo = await isGitRepo(resolvedDir);

      if (!isRepo) {
        errors.push(
          `${projectDir} is not a git repository — skipping worktree creation`
        );
      } else {
        // Get existing worktrees
        const existingWorktrees = await listWorktrees(projectDir);
        const existingBranches = new Set(
          existingWorktrees.map((wt) => wt.branch)
        );

        for (const wt of config.worktrees) {
          // Check if worktree already exists for this branch
          const existing = existingWorktrees.find(
            (ew) =>
              ew.branch === wt.branch ||
              ew.branch ===
                `feature/${wt.name.replace(/\s+/g, "-").toLowerCase()}`
          );

          if (existing) {
            // Worktree exists, just use it
            panes.push({
              role: "worktree",
              name: wt.name,
              command: "claude",
              cwd: existing.path,
            });
          } else {
            // Create new worktree
            try {
              const worktreeInfo: WorktreeInfo = await createWorktree({
                projectPath: projectDir,
                featureName: wt.name,
                baseBranch: "main",
              });

              panes.push({
                role: "worktree",
                name: wt.name,
                command: "claude",
                cwd: worktreeInfo.worktreePath,
              });
            } catch (error) {
              const message =
                error instanceof Error ? error.message : String(error);
              errors.push(`Failed to create worktree "${wt.name}": ${message}`);

              // If branch exists but no worktree, try to use the branch directly
              const hasExistingBranch = await branchExists(
                resolvedDir,
                wt.branch
              );
              if (hasExistingBranch) {
                panes.push({
                  role: "worktree",
                  name: wt.name,
                  command: "claude",
                  cwd: projectDir,
                });
              }
            }
          }
        }
      }
    }

    // 3. Extra panes
    if (config.extras) {
      for (const extra of config.extras) {
        panes.push({
          role: "extra",
          name: extra.name,
          command: extra.command,
          cwd: projectDir,
        });
      }
    }

    return NextResponse.json({
      panes,
      errors: errors.length > 0 ? errors : undefined,
      config,
    });
  } catch (error) {
    console.error("Error setting up workspace:", error);
    return NextResponse.json(
      { error: "Failed to setup workspace" },
      { status: 500 }
    );
  }
}
