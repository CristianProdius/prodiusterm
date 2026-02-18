"use client";

import { useState, useCallback } from "react";
import type { WorktreeStatus } from "@/app/api/worktrees/route";

export function useWorktreeManager() {
  const [worktrees, setWorktrees] = useState<WorktreeStatus[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchWorktrees = useCallback(async (projectDir: string) => {
    setLoading(true);
    try {
      const res = await fetch(
        `/api/worktrees?projectDir=${encodeURIComponent(projectDir)}`
      );
      if (res.ok) {
        const data = await res.json();
        setWorktrees(data.worktrees || []);
      }
    } catch (error) {
      console.error("Failed to fetch worktrees:", error);
    } finally {
      setLoading(false);
    }
  }, []);

  const createWorktree = useCallback(
    async (
      projectDir: string,
      featureName: string,
      baseBranch?: string
    ): Promise<boolean> => {
      try {
        const res = await fetch("/api/worktrees", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ projectDir, featureName, baseBranch }),
        });
        if (res.ok) {
          await fetchWorktrees(projectDir);
          return true;
        }
        const data = await res.json();
        console.error("Create worktree error:", data.error);
        return false;
      } catch (error) {
        console.error("Failed to create worktree:", error);
        return false;
      }
    },
    [fetchWorktrees]
  );

  const deleteWorktreeAction = useCallback(
    async (
      worktreePath: string,
      projectDir: string,
      deleteBranch: boolean
    ): Promise<boolean> => {
      try {
        const res = await fetch("/api/worktrees", {
          method: "DELETE",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ worktreePath, projectDir, deleteBranch }),
        });
        if (res.ok) {
          await fetchWorktrees(projectDir);
          return true;
        }
        return false;
      } catch (error) {
        console.error("Failed to delete worktree:", error);
        return false;
      }
    },
    [fetchWorktrees]
  );

  return {
    worktrees,
    loading,
    fetchWorktrees,
    createWorktree,
    deleteWorktree: deleteWorktreeAction,
  };
}
