"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  GitBranch,
  Plus,
  Trash2,
  RefreshCw,
  Circle,
  ArrowUp,
  ArrowDown,
  Loader2,
  Terminal,
} from "lucide-react";
import { useWorktreeManager } from "@/hooks/useWorktreeManager";
import type { WorktreeStatus } from "@/app/api/worktrees/route";

interface WorktreePanelProps {
  projectDir: string | null;
  projectName: string;
  onOpenInTerminal?: (worktreePath: string) => void;
}

export function WorktreePanel({
  projectDir,
  projectName,
  onOpenInTerminal,
}: WorktreePanelProps) {
  const { worktrees, loading, fetchWorktrees, createWorktree, deleteWorktree } =
    useWorktreeManager();

  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<WorktreeStatus | null>(null);
  const [newFeatureName, setNewFeatureName] = useState("");
  const [newBaseBranch, setNewBaseBranch] = useState("main");
  const [deleteBranch, setDeleteBranch] = useState(false);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    if (projectDir) {
      fetchWorktrees(projectDir);
    }
  }, [projectDir, fetchWorktrees]);

  const handleCreate = async () => {
    if (!projectDir || !newFeatureName.trim()) return;
    setCreating(true);
    await createWorktree(projectDir, newFeatureName.trim(), newBaseBranch);
    setCreating(false);
    setShowCreateDialog(false);
    setNewFeatureName("");
    setNewBaseBranch("main");
  };

  const handleDelete = async () => {
    if (!projectDir || !deleteTarget) return;
    await deleteWorktree(deleteTarget.path, projectDir, deleteBranch);
    setShowDeleteDialog(false);
    setDeleteTarget(null);
    setDeleteBranch(false);
  };

  const confirmDelete = (wt: WorktreeStatus) => {
    setDeleteTarget(wt);
    setShowDeleteDialog(true);
  };

  // Filter out the main worktree (the project dir itself)
  const secondaryWorktrees = worktrees.filter(
    (wt) => wt.branch !== "main" && wt.branch !== "master"
  );

  if (!projectDir) {
    return (
      <div className="text-muted-foreground px-3 py-4 text-center text-xs">
        Select a project to manage worktrees
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-1">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-1.5">
        <div className="flex items-center gap-1.5">
          <GitBranch className="text-muted-foreground h-3.5 w-3.5" />
          <span className="text-xs font-medium">Worktrees</span>
          <span className="text-muted-foreground text-xs">
            ({secondaryWorktrees.length})
          </span>
        </div>
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon-sm"
            className="h-5 w-5"
            onClick={() => fetchWorktrees(projectDir)}
            disabled={loading}
          >
            <RefreshCw className={`h-3 w-3 ${loading ? "animate-spin" : ""}`} />
          </Button>
          <Button
            variant="ghost"
            size="icon-sm"
            className="h-5 w-5"
            onClick={() => setShowCreateDialog(true)}
          >
            <Plus className="h-3 w-3" />
          </Button>
        </div>
      </div>

      {/* Worktree list */}
      {loading && secondaryWorktrees.length === 0 && (
        <div className="flex items-center gap-2 px-3 py-2 text-xs">
          <Loader2 className="h-3 w-3 animate-spin" />
          Loading...
        </div>
      )}

      {!loading && secondaryWorktrees.length === 0 && (
        <div className="text-muted-foreground px-3 py-2 text-xs">
          No feature worktrees
        </div>
      )}

      {secondaryWorktrees.map((wt) => (
        <div
          key={wt.path}
          className="group hover:bg-accent/50 flex items-center gap-2 rounded-md px-3 py-1"
        >
          {/* Status dot */}
          <Circle
            className={`h-2 w-2 flex-shrink-0 ${
              wt.isDirty
                ? "fill-yellow-500 text-yellow-500"
                : "fill-green-500 text-green-500"
            }`}
          />

          {/* Branch name */}
          <div className="min-w-0 flex-1">
            <div className="truncate text-xs font-medium">
              {wt.branch.replace("feature/", "")}
            </div>
            <div className="text-muted-foreground flex items-center gap-1.5 text-[10px]">
              <span className="font-mono">{wt.head.slice(0, 7)}</span>
              {wt.ahead > 0 && (
                <span className="flex items-center gap-0.5 text-green-600">
                  <ArrowUp className="h-2 w-2" />
                  {wt.ahead}
                </span>
              )}
              {wt.behind > 0 && (
                <span className="flex items-center gap-0.5 text-red-500">
                  <ArrowDown className="h-2 w-2" />
                  {wt.behind}
                </span>
              )}
              {wt.isDirty && <span className="text-yellow-600">modified</span>}
            </div>
          </div>

          {/* Actions */}
          <div className="flex flex-shrink-0 items-center gap-0.5 opacity-0 transition-opacity group-hover:opacity-100">
            {onOpenInTerminal && (
              <Button
                variant="ghost"
                size="icon-sm"
                className="h-5 w-5"
                onClick={() => onOpenInTerminal(wt.path)}
                title="Open in terminal"
              >
                <Terminal className="h-3 w-3" />
              </Button>
            )}
            <Button
              variant="ghost"
              size="icon-sm"
              className="h-5 w-5 text-red-500 hover:text-red-600"
              onClick={() => confirmDelete(wt)}
              title="Delete worktree"
            >
              <Trash2 className="h-3 w-3" />
            </Button>
          </div>
        </div>
      ))}

      {/* Create Dialog */}
      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>New Worktree</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 py-2">
            <div>
              <label className="text-muted-foreground mb-1 block text-xs">
                Feature Name
              </label>
              <input
                type="text"
                value={newFeatureName}
                onChange={(e) => setNewFeatureName(e.target.value)}
                placeholder="e.g. add-dark-mode"
                className="border-input bg-background w-full rounded-md border px-3 py-1.5 text-sm"
                onKeyDown={(e) => e.key === "Enter" && handleCreate()}
                autoFocus
              />
              <p className="text-muted-foreground mt-1 text-xs">
                Branch: feature/
                {newFeatureName.replace(/\s+/g, "-").toLowerCase() || "..."}
              </p>
            </div>
            <div>
              <label className="text-muted-foreground mb-1 block text-xs">
                Base Branch
              </label>
              <input
                type="text"
                value={newBaseBranch}
                onChange={(e) => setNewBaseBranch(e.target.value)}
                className="border-input bg-background w-full rounded-md border px-3 py-1.5 text-sm"
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowCreateDialog(false)}
            >
              Cancel
            </Button>
            <Button
              onClick={handleCreate}
              disabled={!newFeatureName.trim() || creating}
            >
              {creating ? (
                <>
                  <Loader2 className="mr-1 h-3 w-3 animate-spin" />
                  Creating...
                </>
              ) : (
                "Create"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Worktree</DialogTitle>
          </DialogHeader>
          <div className="space-y-3 py-2">
            <p className="text-sm">
              Delete worktree for branch{" "}
              <code className="bg-muted rounded px-1 text-xs">
                {deleteTarget?.branch}
              </code>
              ?
            </p>
            {deleteTarget?.isDirty && (
              <p className="text-sm text-yellow-600">
                This worktree has uncommitted changes that will be lost.
              </p>
            )}
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={deleteBranch}
                onChange={(e) => setDeleteBranch(e.target.checked)}
                className="rounded"
              />
              Also delete the branch
            </label>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDeleteDialog(false)}
            >
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
