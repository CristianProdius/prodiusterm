import AppKit
import SwiftTerm

/// Terminal color theme definition, ported from lib/terminal-themes.ts
struct TerminalTheme: Equatable, Identifiable {
    let id: String
    let mode: ThemeMode
    let background: NSColor
    let foreground: NSColor
    let cursor: NSColor
    let cursorAccent: NSColor
    let selectionBackground: NSColor

    // ANSI colors
    let black: NSColor
    let red: NSColor
    let green: NSColor
    let yellow: NSColor
    let blue: NSColor
    let magenta: NSColor
    let cyan: NSColor
    let white: NSColor
    let brightBlack: NSColor
    let brightRed: NSColor
    let brightGreen: NSColor
    let brightYellow: NSColor
    let brightBlue: NSColor
    let brightMagenta: NSColor
    let brightCyan: NSColor
    let brightWhite: NSColor
}

enum ThemeMode: String, CaseIterable {
    case dark
    case light
}

// MARK: - SwiftTerm Color Conversion

extension TerminalTheme {
    /// Convert to SwiftTerm color array for terminal rendering
    var ansiColors: [Color] {
        [
            nsColorToTermColor(black),
            nsColorToTermColor(red),
            nsColorToTermColor(green),
            nsColorToTermColor(yellow),
            nsColorToTermColor(blue),
            nsColorToTermColor(magenta),
            nsColorToTermColor(cyan),
            nsColorToTermColor(white),
            nsColorToTermColor(brightBlack),
            nsColorToTermColor(brightRed),
            nsColorToTermColor(brightGreen),
            nsColorToTermColor(brightYellow),
            nsColorToTermColor(brightBlue),
            nsColorToTermColor(brightMagenta),
            nsColorToTermColor(brightCyan),
            nsColorToTermColor(brightWhite),
        ]
    }

    var foregroundColor: Color { nsColorToTermColor(foreground) }
    var backgroundColor: Color { nsColorToTermColor(background) }
    var cursorColor: Color { nsColorToTermColor(cursor) }

    private func nsColorToTermColor(_ color: NSColor) -> Color {
        let c = color.usingColorSpace(.deviceRGB) ?? color
        return Color(
            red: UInt16(c.redComponent * 65535),
            green: UInt16(c.greenComponent * 65535),
            blue: UInt16(c.blueComponent * 65535)
        )
    }
}

// MARK: - Hex Color Parsing

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: String(hex.prefix(6))).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        // Handle alpha from 8-char hex (e.g. "#3B82F640")
        let a: CGFloat
        if hex.count == 8 {
            var alpha: UInt64 = 0
            Scanner(string: String(hex.suffix(2))).scanHexInt64(&alpha)
            a = CGFloat(alpha) / 255.0
        } else {
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Base ANSI Palettes

private let darkANSI = (
    black: NSColor(hex: "#1a1a1a"),
    red: NSColor(hex: "#ff5555"),
    green: NSColor(hex: "#50fa7b"),
    yellow: NSColor(hex: "#f1fa8c"),
    blue: NSColor(hex: "#6272a4"),
    magenta: NSColor(hex: "#ff79c6"),
    cyan: NSColor(hex: "#8be9fd"),
    white: NSColor(hex: "#f8f8f2"),
    brightBlack: NSColor(hex: "#6272a4"),
    brightRed: NSColor(hex: "#ff6e6e"),
    brightGreen: NSColor(hex: "#69ff94"),
    brightYellow: NSColor(hex: "#ffffa5"),
    brightBlue: NSColor(hex: "#d6acff"),
    brightMagenta: NSColor(hex: "#ff92df"),
    brightCyan: NSColor(hex: "#a4ffff"),
    brightWhite: NSColor(hex: "#ffffff")
)

private let lightANSI = (
    black: NSColor(hex: "#000000"),
    red: NSColor(hex: "#c91b00"),
    green: NSColor(hex: "#00c200"),
    yellow: NSColor(hex: "#c7c400"),
    blue: NSColor(hex: "#0225c7"),
    magenta: NSColor(hex: "#c930c7"),
    cyan: NSColor(hex: "#00c5c7"),
    white: NSColor(hex: "#c7c7c7"),
    brightBlack: NSColor(hex: "#686868"),
    brightRed: NSColor(hex: "#ff6e67"),
    brightGreen: NSColor(hex: "#5ffa68"),
    brightYellow: NSColor(hex: "#fffc67"),
    brightBlue: NSColor(hex: "#6871ff"),
    brightMagenta: NSColor(hex: "#ff76ff"),
    brightCyan: NSColor(hex: "#5ffdff"),
    brightWhite: NSColor(hex: "#ffffff")
)

// MARK: - Theme Registry

struct TerminalThemeRegistry {
    static let shared = TerminalThemeRegistry()

    let darkThemes: [String: TerminalTheme]
    let lightThemes: [String: TerminalTheme]

    var allThemes: [TerminalTheme] {
        Array(darkThemes.values) + Array(lightThemes.values)
    }

    private init() {
        // Dark themes
        darkThemes = [
            "deep": Self.buildDarkTheme(id: "dark-deep", variant: "deep",
                background: "#0A0A0A", foreground: "#EBEBEB",
                cursor: "#3B82F6", cursorAccent: "#0A0A0A", selection: "#3B82F640"),
            "charcoal": Self.buildDarkTheme(id: "dark-charcoal", variant: "charcoal",
                background: "#161A1D", foreground: "#E8EAEB",
                cursor: "#5B9BD5", cursorAccent: "#161A1D", selection: "#5B9BD540"),
            "warm": Self.buildDarkTheme(id: "dark-warm", variant: "warm",
                background: "#1A1612", foreground: "#E8DCC8",
                cursor: "#F59E0B", cursorAccent: "#1A1612", selection: "#F59E0B40",
                overrides: ["yellow": "#F59E0B", "brightYellow": "#FBBF24"]),
            "cool": Self.buildDarkTheme(id: "dark-cool", variant: "cool",
                background: "#0D1117", foreground: "#E6EDF3",
                cursor: "#58A6FF", cursorAccent: "#0D1117", selection: "#58A6FF40",
                overrides: ["blue": "#58A6FF", "brightBlue": "#79C0FF"]),
            "gray": Self.buildDarkTheme(id: "dark-gray", variant: "gray",
                background: "#191919", foreground: "#DEDEDE",
                cursor: "#2383E2", cursorAccent: "#191919", selection: "#2383E240"),
            "midnight": Self.buildDarkTheme(id: "dark-midnight", variant: "midnight",
                background: "#0A0E1A", foreground: "#E5E9F0",
                cursor: "#88C0D0", cursorAccent: "#0A0E1A", selection: "#88C0D040",
                overrides: ["cyan": "#88C0D0", "blue": "#5E81AC", "brightCyan": "#8FBCBB", "brightBlue": "#81A1C1"]),
            "forest": Self.buildDarkTheme(id: "dark-forest", variant: "forest",
                background: "#0C1410", foreground: "#E8F0ED",
                cursor: "#50C878", cursorAccent: "#0C1410", selection: "#50C87840",
                overrides: ["green": "#50C878", "brightGreen": "#6EE7A0"]),
            "purple": Self.buildDarkTheme(id: "dark-purple", variant: "purple",
                background: "#0F0A1A", foreground: "#E8E5F0",
                cursor: "#A855F7", cursorAccent: "#0F0A1A", selection: "#A855F740",
                overrides: ["magenta": "#A855F7", "brightMagenta": "#C084FC"]),
            "ocean": Self.buildDarkTheme(id: "dark-ocean", variant: "ocean",
                background: "#0A1419", foreground: "#E5EBF0",
                cursor: "#14B8A6", cursorAccent: "#0A1419", selection: "#14B8A640",
                overrides: ["cyan": "#14B8A6", "brightCyan": "#2DD4BF"]),
            "mocha": Self.buildDarkTheme(id: "dark-mocha", variant: "mocha",
                background: "#1C1612", foreground: "#E6DDD4",
                cursor: "#D4844A", cursorAccent: "#1C1612", selection: "#D4844A40",
                overrides: ["yellow": "#D4844A", "brightYellow": "#E8A76A"]),
        ]

        // Light themes
        lightThemes = [
            "default": Self.buildLightTheme(id: "light-default", variant: "default",
                background: "#FFFFFF", foreground: "#1a1a1a",
                cursor: "#3B82F6", cursorAccent: "#FFFFFF", selection: "#3B82F630"),
            "warm": Self.buildLightTheme(id: "light-warm", variant: "warm",
                background: "#F5F1E8", foreground: "#2D2519",
                cursor: "#D97706", cursorAccent: "#F5F1E8", selection: "#D9770630"),
            "cool": Self.buildLightTheme(id: "light-cool", variant: "cool",
                background: "#F0F4F8", foreground: "#1E293B",
                cursor: "#0EA5E9", cursorAccent: "#F0F4F8", selection: "#0EA5E930"),
            "soft": Self.buildLightTheme(id: "light-soft", variant: "soft",
                background: "#F8F9FA", foreground: "#212529",
                cursor: "#6366F1", cursorAccent: "#F8F9FA", selection: "#6366F130"),
            "rose": Self.buildLightTheme(id: "light-rose", variant: "rose",
                background: "#FAF5F7", foreground: "#2D1A22",
                cursor: "#E74C8C", cursorAccent: "#FAF5F7", selection: "#E74C8C30"),
            "lavender": Self.buildLightTheme(id: "light-lavender", variant: "lavender",
                background: "#F7F5FA", foreground: "#1F1A2D",
                cursor: "#9F7AEA", cursorAccent: "#F7F5FA", selection: "#9F7AEA30"),
            "mint": Self.buildLightTheme(id: "light-mint", variant: "mint",
                background: "#F0F9F6", foreground: "#14291F",
                cursor: "#28B88B", cursorAccent: "#F0F9F6", selection: "#28B88B30"),
            "peach": Self.buildLightTheme(id: "light-peach", variant: "peach",
                background: "#F9F4F0", foreground: "#2D1F19",
                cursor: "#FA8B6C", cursorAccent: "#F9F4F0", selection: "#FA8B6C30"),
        ]
    }

    /// Get a theme by theme string (e.g. "dark-deep", "light-warm", "dark", "system")
    func theme(for themeString: String) -> TerminalTheme {
        if themeString == "system" {
            return darkThemes["deep"]!
        }

        let parts = themeString.split(separator: "-", maxSplits: 1)
        let mode = String(parts[0])
        let variant = parts.count > 1 ? String(parts[1]) : (mode == "dark" ? "deep" : "default")

        if mode == "light" {
            return lightThemes[variant] ?? lightThemes["default"]!
        }
        return darkThemes[variant] ?? darkThemes["deep"]!
    }

    // MARK: - Theme Builders

    private static func buildDarkTheme(
        id: String, variant: String,
        background: String, foreground: String,
        cursor: String, cursorAccent: String, selection: String,
        overrides: [String: String] = [:]
    ) -> TerminalTheme {
        TerminalTheme(
            id: id,
            mode: .dark,
            background: NSColor(hex: background),
            foreground: NSColor(hex: foreground),
            cursor: NSColor(hex: cursor),
            cursorAccent: NSColor(hex: cursorAccent),
            selectionBackground: NSColor(hex: selection),
            black: NSColor(hex: overrides["black"] ?? "#1a1a1a"),
            red: NSColor(hex: overrides["red"] ?? "#ff5555"),
            green: NSColor(hex: overrides["green"] ?? "#50fa7b"),
            yellow: NSColor(hex: overrides["yellow"] ?? "#f1fa8c"),
            blue: NSColor(hex: overrides["blue"] ?? "#6272a4"),
            magenta: NSColor(hex: overrides["magenta"] ?? "#ff79c6"),
            cyan: NSColor(hex: overrides["cyan"] ?? "#8be9fd"),
            white: NSColor(hex: overrides["white"] ?? "#f8f8f2"),
            brightBlack: NSColor(hex: overrides["brightBlack"] ?? "#6272a4"),
            brightRed: NSColor(hex: overrides["brightRed"] ?? "#ff6e6e"),
            brightGreen: NSColor(hex: overrides["brightGreen"] ?? "#69ff94"),
            brightYellow: NSColor(hex: overrides["brightYellow"] ?? "#ffffa5"),
            brightBlue: NSColor(hex: overrides["brightBlue"] ?? "#d6acff"),
            brightMagenta: NSColor(hex: overrides["brightMagenta"] ?? "#ff92df"),
            brightCyan: NSColor(hex: overrides["brightCyan"] ?? "#a4ffff"),
            brightWhite: NSColor(hex: overrides["brightWhite"] ?? "#ffffff")
        )
    }

    private static func buildLightTheme(
        id: String, variant: String,
        background: String, foreground: String,
        cursor: String, cursorAccent: String, selection: String,
        overrides: [String: String] = [:]
    ) -> TerminalTheme {
        TerminalTheme(
            id: id,
            mode: .light,
            background: NSColor(hex: background),
            foreground: NSColor(hex: foreground),
            cursor: NSColor(hex: cursor),
            cursorAccent: NSColor(hex: cursorAccent),
            selectionBackground: NSColor(hex: selection),
            black: NSColor(hex: overrides["black"] ?? "#000000"),
            red: NSColor(hex: overrides["red"] ?? "#c91b00"),
            green: NSColor(hex: overrides["green"] ?? "#00c200"),
            yellow: NSColor(hex: overrides["yellow"] ?? "#c7c400"),
            blue: NSColor(hex: overrides["blue"] ?? "#0225c7"),
            magenta: NSColor(hex: overrides["magenta"] ?? "#c930c7"),
            cyan: NSColor(hex: overrides["cyan"] ?? "#00c5c7"),
            white: NSColor(hex: overrides["white"] ?? "#c7c7c7"),
            brightBlack: NSColor(hex: overrides["brightBlack"] ?? "#686868"),
            brightRed: NSColor(hex: overrides["brightRed"] ?? "#ff6e67"),
            brightGreen: NSColor(hex: overrides["brightGreen"] ?? "#5ffa68"),
            brightYellow: NSColor(hex: overrides["brightYellow"] ?? "#fffc67"),
            brightBlue: NSColor(hex: overrides["brightBlue"] ?? "#6871ff"),
            brightMagenta: NSColor(hex: overrides["brightMagenta"] ?? "#ff76ff"),
            brightCyan: NSColor(hex: overrides["brightCyan"] ?? "#5ffdff"),
            brightWhite: NSColor(hex: overrides["brightWhite"] ?? "#ffffff")
        )
    }
}
