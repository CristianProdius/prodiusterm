"use client";

import { useState, useCallback } from "react";
import type { WorkspacePaneCommand } from "@/lib/workspace-config";
import type { WorkspaceConfig } from "@/lib/workspace-config";

interface WorkspaceSetupResult {
  panes: WorkspacePaneCommand[];
  errors?: string[];
  config: WorkspaceConfig;
}

export function useWorkspaceSetup() {
  const [loading, setLoading] = useState(false);
  const [lastSetup, setLastSetup] = useState<WorkspaceSetupResult | null>(null);

  /**
   * Check if a project has a .workspace.json
   */
  const checkWorkspaceConfig = useCallback(
    async (projectDir: string): Promise<WorkspaceConfig | null> => {
      try {
        const res = await fetch(
          `/api/workspace?projectDir=${encodeURIComponent(projectDir)}`
        );
        if (!res.ok) {
          console.error("Failed to check workspace config:", res.status);
          return null;
        }
        const data = await res.json();
        return data.config || null;
      } catch (error) {
        console.error("Workspace config check error:", error);
        return null;
      }
    },
    []
  );

  /**
   * Setup workspace: parse config, create worktrees, return pane commands
   */
  const setupWorkspace = useCallback(
    async (projectDir: string): Promise<WorkspaceSetupResult | null> => {
      setLoading(true);
      try {
        const res = await fetch("/api/workspace/setup", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ projectDir }),
        });

        if (!res.ok) {
          const data = await res.json();
          console.error("Workspace setup failed:", data.error);
          return null;
        }

        const result: WorkspaceSetupResult = await res.json();
        setLastSetup(result);
        return result;
      } catch (error) {
        console.error("Workspace setup error:", error);
        return null;
      } finally {
        setLoading(false);
      }
    },
    []
  );

  /**
   * Create a .workspace.json template
   */
  const createTemplate = useCallback(
    async (projectDir: string): Promise<string | null> => {
      try {
        const res = await fetch("/api/workspace", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ projectDir }),
        });
        if (!res.ok) {
          const data = await res.json();
          console.error("Failed to create workspace template:", data.error);
          return null;
        }
        const data = await res.json();
        return data.configPath || null;
      } catch (error) {
        console.error("Workspace template creation error:", error);
        return null;
      }
    },
    []
  );

  return {
    loading,
    lastSetup,
    checkWorkspaceConfig,
    setupWorkspace,
    createTemplate,
  };
}
