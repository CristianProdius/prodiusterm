// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::net::TcpStream;
use std::path::PathBuf;
use std::process::{Child, Command};
use std::sync::Mutex;
use std::thread;
use std::time::Duration;
use tauri::Manager;

struct ServerProcess(Mutex<Option<Child>>);

/// Find a Node.js binary — Finder.app doesn't inherit shell PATH.
fn find_node() -> String {
    for path in [
        "/opt/homebrew/bin/node",
        "/usr/local/bin/node",
        "/usr/bin/node",
    ] {
        if std::path::Path::new(path).exists() {
            return path.to_string();
        }
    }
    "node".to_string() // fallback to PATH lookup
}

/// Find the project root directory containing server files.
/// Strategy:
/// 1. Check PRODIUSTERM_ROOT env var (explicit override)
/// 2. Check relative to the executable (for dev mode: binary is in src-tauri/target/...)
/// 3. Check current working directory
/// 4. Check next to the executable's ancestor dirs (for bundled .app)
fn find_project_root() -> Option<PathBuf> {
    // 1. Explicit env var
    if let Ok(root) = std::env::var("PRODIUSTERM_ROOT") {
        let path = PathBuf::from(&root);
        if path.join("server.ts").exists() || path.join("dist/server.js").exists() {
            println!("Found project root via PRODIUSTERM_ROOT: {:?}", path);
            return Some(path);
        }
    }

    // 2. Walk up from the executable path (works in dev mode)
    if let Ok(exe) = std::env::current_exe() {
        let mut dir = exe.parent().map(|p| p.to_path_buf());
        for _ in 0..10 {
            if let Some(ref d) = dir {
                if d.join("server.ts").exists() || d.join("dist/server.js").exists() {
                    println!("Found project root relative to exe: {:?}", d);
                    return Some(d.clone());
                }
                dir = d.parent().map(|p| p.to_path_buf());
            } else {
                break;
            }
        }
    }

    // 3. Current working directory
    if let Ok(cwd) = std::env::current_dir() {
        if cwd.join("server.ts").exists() || cwd.join("dist/server.js").exists() {
            println!("Found project root via CWD: {:?}", cwd);
            return Some(cwd);
        }
        // Also check parent (in case CWD is src-tauri)
        if let Some(parent) = cwd.parent() {
            if parent.join("server.ts").exists() || parent.join("dist/server.js").exists() {
                println!("Found project root via CWD parent: {:?}", parent);
                return Some(parent.to_path_buf());
            }
        }
    }

    // 4. For macOS .app bundles: check Resources dir for server-bundle
    if let Ok(exe) = std::env::current_exe() {
        // exe is at ProdiusTerm.app/Contents/MacOS/ProdiusTerm
        // Resources would be at ProdiusTerm.app/Contents/Resources/
        if let Some(macos_dir) = exe.parent() {
            let resources_dir = macos_dir.parent()
                .map(|contents| contents.join("Resources"));
            if let Some(ref res) = resources_dir {
                if res.join("server-bundle/server.js").exists() {
                    println!("Found project root in Resources: {:?}", res);
                    return Some(res.clone());
                }
            }
        }
    }

    None
}

fn start_server() -> Option<Child> {
    let project_root = match find_project_root() {
        Some(root) => root,
        None => {
            eprintln!("Could not find project root with server files.");
            eprintln!("Set PRODIUSTERM_ROOT env var to the project directory,");
            eprintln!("or run from the project directory.");
            return None;
        }
    };

    let node = find_node();
    let bundle_server = project_root.join("server-bundle/server.js");

    // Priority: server-bundle (production .app) > dist/server.js > dev tsx
    let (cmd, args, working_dir) = if bundle_server.exists() {
        // Production: server-bundle inside .app Resources
        (node.clone(), vec!["server-bundle/server.js".to_string()], project_root)
    } else if project_root.join("dist/server.js").exists() {
        (node.clone(), vec!["dist/server.js".to_string()], project_root)
    } else {
        // Development mode - run with tsx
        ("npx".to_string(), vec!["tsx".to_string(), "server.ts".to_string()], project_root)
    };

    println!("Starting ProdiusTerm server...");
    println!("Working dir: {:?}", working_dir);
    println!("Command: {} {:?}", cmd, args);

    // Augment PATH so node/npx can be found when launched from Finder
    let augmented_path = format!(
        "/opt/homebrew/bin:/usr/local/bin:{}",
        std::env::var("PATH").unwrap_or_default()
    );

    let child = Command::new(&cmd)
        .args(&args)
        .current_dir(&working_dir)
        .env("NODE_ENV", "production")
        .env("PATH", &augmented_path)
        .spawn()
        .ok()?;

    println!("Server started with PID: {}", child.id());
    Some(child)
}

fn wait_for_server(host: &str, port: u16, max_attempts: u32) -> bool {
    for attempt in 1..=max_attempts {
        if TcpStream::connect((host, port)).is_ok() {
            println!("Server ready after {} attempts", attempt);
            return true;
        }
        println!("Waiting for server... attempt {}/{}", attempt, max_attempts);
        thread::sleep(Duration::from_millis(500));
    }
    false
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            // Start the Node.js server
            let server = start_server();

            if server.is_some() {
                // Wait for server to be ready (max 30 seconds)
                let ready = wait_for_server("127.0.0.1", 3011, 60);
                if !ready {
                    eprintln!("Warning: Server may not be ready");
                }
            } else {
                eprintln!("Warning: Could not start server - assuming it's already running");
            }

            // Store the server process handle for cleanup
            app.manage(ServerProcess(Mutex::new(server)));

            Ok(())
        })
        .on_window_event(|window, event| {
            if let tauri::WindowEvent::CloseRequested { .. } = event {
                // Kill the server when window closes
                if let Some(state) = window.try_state::<ServerProcess>() {
                    if let Ok(mut guard) = state.0.lock() {
                        if let Some(mut child) = guard.take() {
                            println!("Stopping server...");
                            let _ = child.kill();
                        }
                    }
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
