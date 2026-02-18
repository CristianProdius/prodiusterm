import { NextRequest, NextResponse } from "next/server";
import { listWorktrees, createWorktree, deleteWorktree } from "@/lib/worktrees";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

function resolvePath(p: string): string {
  return p.replace(/^~/, process.env.HOME || "~");
}

export interface WorktreeStatus {
  path: string;
  branch: string;
  head: string;
  isDirty: boolean;
  ahead: number;
  behind: number;
}

async function getWorktreeStatus(worktreePath: string): Promise<{
  isDirty: boolean;
  ahead: number;
  behind: number;
}> {
  const resolved = resolvePath(worktreePath);
  try {
    // Check dirty status
    const { stdout: statusOutput } = await execAsync(
      `git -C "${resolved}" status --porcelain 2>/dev/null`,
      { timeout: 5000 }
    );
    const isDirty = statusOutput.trim().length > 0;

    // Check ahead/behind
    let ahead = 0;
    let behind = 0;
    try {
      const { stdout: abOutput } = await execAsync(
        `git -C "${resolved}" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null`,
        { timeout: 5000 }
      );
      const parts = abOutput.trim().split(/\s+/);
      if (parts.length === 2) {
        ahead = parseInt(parts[0], 10) || 0;
        behind = parseInt(parts[1], 10) || 0;
      }
    } catch {
      // No upstream configured
    }

    return { isDirty, ahead, behind };
  } catch {
    return { isDirty: false, ahead: 0, behind: 0 };
  }
}

/**
 * GET /api/worktrees?projectDir=/path/to/project
 * List all worktrees with status info
 */
export async function GET(request: NextRequest) {
  const projectDir = request.nextUrl.searchParams.get("projectDir");
  if (!projectDir) {
    return NextResponse.json(
      { error: "projectDir is required" },
      { status: 400 }
    );
  }

  try {
    const worktrees = await listWorktrees(projectDir);
    const withStatus: WorktreeStatus[] = await Promise.all(
      worktrees.map(async (wt) => {
        const status = await getWorktreeStatus(wt.path);
        return {
          path: wt.path,
          branch: wt.branch,
          head: wt.head,
          ...status,
        };
      })
    );

    return NextResponse.json({ worktrees: withStatus });
  } catch (error) {
    console.error("Error listing worktrees:", error);
    return NextResponse.json(
      { error: "Failed to list worktrees" },
      { status: 500 }
    );
  }
}

/**
 * POST /api/worktrees
 * Create a new worktree
 */
export async function POST(request: NextRequest) {
  try {
    const { projectDir, featureName, baseBranch } = await request.json();
    if (!projectDir || !featureName) {
      return NextResponse.json(
        { error: "projectDir and featureName are required" },
        { status: 400 }
      );
    }

    const worktreeInfo = await createWorktree({
      projectPath: projectDir,
      featureName,
      baseBranch,
    });

    return NextResponse.json({ worktree: worktreeInfo }, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return NextResponse.json(
      { error: `Failed to create worktree: ${message}` },
      { status: 400 }
    );
  }
}

/**
 * DELETE /api/worktrees
 * Delete a worktree
 */
export async function DELETE(request: NextRequest) {
  try {
    const { worktreePath, projectDir, deleteBranch } = await request.json();
    if (!worktreePath || !projectDir) {
      return NextResponse.json(
        { error: "worktreePath and projectDir are required" },
        { status: 400 }
      );
    }

    await deleteWorktree(worktreePath, projectDir, deleteBranch);
    return NextResponse.json({ success: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return NextResponse.json(
      { error: `Failed to delete worktree: ${message}` },
      { status: 400 }
    );
  }
}
