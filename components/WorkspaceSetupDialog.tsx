"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import {
  Server,
  GitBranch,
  Terminal,
  Loader2,
  AlertCircle,
} from "lucide-react";
import type { WorkspacePaneCommand } from "@/lib/workspace-config";

interface WorkspaceSetupDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  projectName: string;
  projectDir: string;
  onSetup: (projectDir: string) => Promise<{
    panes: WorkspacePaneCommand[];
    errors?: string[];
  } | null>;
  onApply: (panes: WorkspacePaneCommand[]) => void;
}

export function WorkspaceSetupDialog({
  open,
  onOpenChange,
  projectName,
  projectDir,
  onSetup,
  onApply,
}: WorkspaceSetupDialogProps) {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{
    panes: WorkspacePaneCommand[];
    errors?: string[];
  } | null>(null);

  const handleSetup = async () => {
    setLoading(true);
    try {
      const setupResult = await onSetup(projectDir);
      setResult(setupResult);
    } finally {
      setLoading(false);
    }
  };

  const handleApply = () => {
    if (result?.panes) {
      onApply(result.panes);
      onOpenChange(false);
      setResult(null);
    }
  };

  const roleIcon = (role: string) => {
    switch (role) {
      case "server":
        return <Server className="h-4 w-4 text-green-500" />;
      case "worktree":
        return <GitBranch className="h-4 w-4 text-blue-500" />;
      default:
        return <Terminal className="h-4 w-4 text-yellow-500" />;
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Workspace Setup</DialogTitle>
          <DialogDescription>
            <strong>{projectName}</strong> has a <code>.workspace.json</code>{" "}
            config. Set up the workspace to auto-create panes with your dev
            server, worktrees, and tools.
          </DialogDescription>
        </DialogHeader>

        {!result && !loading && (
          <div className="py-4">
            <p className="text-muted-foreground text-sm">
              This will read <code>.workspace.json</code> from{" "}
              <code>{projectDir}</code>, create any missing git worktrees, and
              prepare terminal panes for each configured service.
            </p>
          </div>
        )}

        {loading && (
          <div className="flex items-center gap-3 py-8">
            <Loader2 className="h-5 w-5 animate-spin" />
            <span>Setting up workspace...</span>
          </div>
        )}

        {result && (
          <div className="space-y-3 py-2">
            {result.panes.map((pane, i) => (
              <div
                key={i}
                className="bg-muted/50 flex items-center gap-3 rounded-md px-3 py-2"
              >
                {roleIcon(pane.role)}
                <div className="min-w-0 flex-1">
                  <div className="text-sm font-medium">{pane.name}</div>
                  <div className="text-muted-foreground truncate font-mono text-xs">
                    {pane.command}
                  </div>
                </div>
                <span className="text-muted-foreground text-xs capitalize">
                  {pane.role}
                </span>
              </div>
            ))}

            {result.errors && result.errors.length > 0 && (
              <div className="space-y-1">
                {result.errors.map((err, i) => (
                  <div
                    key={i}
                    className="flex items-start gap-2 text-xs text-yellow-600 dark:text-yellow-400"
                  >
                    <AlertCircle className="mt-0.5 h-3 w-3 shrink-0" />
                    <span>{err}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => {
              setResult(null);
              onOpenChange(false);
            }}
          >
            Cancel
          </Button>
          {!result ? (
            <Button onClick={handleSetup} disabled={loading}>
              {loading ? "Setting up..." : "Setup Workspace"}
            </Button>
          ) : (
            <Button onClick={handleApply}>
              Open {result.panes.length} Panes
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
