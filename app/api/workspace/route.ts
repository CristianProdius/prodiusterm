import { NextRequest, NextResponse } from "next/server";
import {
  readWorkspaceConfig,
  writeWorkspaceTemplate,
} from "@/lib/workspace-config";

/**
 * GET /api/workspace?projectDir=/path/to/project
 * Read .workspace.json from a project directory
 */
export async function GET(request: NextRequest) {
  const projectDir = request.nextUrl.searchParams.get("projectDir");
  if (!projectDir) {
    return NextResponse.json(
      { error: "projectDir query parameter is required" },
      { status: 400 }
    );
  }

  const config = readWorkspaceConfig(projectDir);
  return NextResponse.json({ config, projectDir });
}

/**
 * POST /api/workspace
 * Create a .workspace.json template in a project directory
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

    const configPath = writeWorkspaceTemplate(projectDir);
    return NextResponse.json({ configPath }, { status: 201 });
  } catch (error) {
    console.error("Error creating workspace template:", error);
    return NextResponse.json(
      { error: "Failed to create workspace template" },
      { status: 500 }
    );
  }
}
