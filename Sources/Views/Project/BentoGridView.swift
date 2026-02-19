import SwiftUI

struct BentoGridView: View {
    @Bindable var model: ProjectWorkspaceModel
    let terminalManager: TerminalSessionManager
    let theme: TerminalTheme
    let fontSize: CGFloat
    let onEdit: (ProjectTerminal) -> Void
    let onDelete: (ProjectTerminal) -> Void
    let onLayoutCommit: (ProjectTerminalLayout) -> Void
    let onBringToFront: (String) -> Void

    private let minTileSize = CGSize(width: 260, height: 180)
    private let gridStep: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(model.terminals, id: \.id) { terminal in
                    let layoutBinding = model.layoutBinding(for: terminal)
                    let layout = layoutBinding.wrappedValue
                    if !layout.isHidden {
                        TerminalTileView(
                            terminal: terminal,
                            layout: layoutBinding,
                            containerSize: geo.size,
                            theme: theme,
                            fontSize: fontSize,
                            terminalManager: terminalManager,
                            minTileSize: minTileSize,
                            gridStep: gridStep,
                            onEdit: { onEdit(terminal) },
                            onDelete: { onDelete(terminal) },
                            onLayoutCommit: onLayoutCommit,
                            onBringToFront: { onBringToFront(terminal.id) }
                        )
                        .zIndex(Double(layout.zIndex))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct TerminalTileView: View {
    let terminal: ProjectTerminal
    @Binding var layout: ProjectTerminalLayout
    let containerSize: CGSize
    let theme: TerminalTheme
    let fontSize: CGFloat
    let terminalManager: TerminalSessionManager
    let minTileSize: CGSize
    let gridStep: CGFloat
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onLayoutCommit: (ProjectTerminalLayout) -> Void
    let onBringToFront: () -> Void

    @State private var dragStartFrame: CGRect?
    @State private var resizeStartFrame: CGRect?

    var body: some View {
        let frame = currentFrame

        VStack(spacing: 0) {
            tileHeader
            SwiftTermView(
                terminal: terminal,
                terminalManager: terminalManager,
                theme: theme,
                fontSize: fontSize
            )
        }
        .frame(width: frame.width, height: frame.height)
        .background(Color(nsColor: theme.background))
        .overlay(alignment: .bottomTrailing) {
            resizeHandle
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .position(x: frame.midX, y: frame.midY)
        .gesture(dragGesture)
        .onTapGesture {
            onBringToFront()
        }
    }

    private var tileHeader: some View {
        HStack(spacing: 8) {
            Text(terminal.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(terminal.kind.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 10))
            .padding(6)
            .foregroundStyle(.secondary)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
            .gesture(resizeGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragStartFrame == nil {
                    dragStartFrame = currentFrame
                    onBringToFront()
                }
                guard var frame = dragStartFrame else { return }
                frame.origin.x += value.translation.width
                frame.origin.y += value.translation.height
                frame.origin.x = snap(frame.origin.x, step: gridStep)
                frame.origin.y = snap(frame.origin.y, step: gridStep)
                updateLayout(from: frame)
            }
            .onEnded { _ in
                dragStartFrame = nil
                onLayoutCommit(layout)
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if resizeStartFrame == nil {
                    resizeStartFrame = currentFrame
                    onBringToFront()
                }
                guard var frame = resizeStartFrame else { return }
                frame.size.width += value.translation.width
                frame.size.height += value.translation.height
                frame.size.width = max(minTileSize.width, snap(frame.size.width, step: gridStep))
                frame.size.height = max(minTileSize.height, snap(frame.size.height, step: gridStep))

                frame.size.width = min(frame.size.width, containerSize.width - frame.origin.x)
                frame.size.height = min(frame.size.height, containerSize.height - frame.origin.y)

                updateLayout(from: frame)
            }
            .onEnded { _ in
                resizeStartFrame = nil
                onLayoutCommit(layout)
            }
    }

    private var currentFrame: CGRect {
        let width = max(layout.width * containerSize.width, minTileSize.width)
        let height = max(layout.height * containerSize.height, minTileSize.height)
        let x = min(max(layout.x * containerSize.width, 0), containerSize.width - width)
        let y = min(max(layout.y * containerSize.height, 0), containerSize.height - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func updateLayout(from frame: CGRect) {
        let clampedX = max(0, min(frame.origin.x, containerSize.width - frame.width))
        let clampedY = max(0, min(frame.origin.y, containerSize.height - frame.height))
        let clampedWidth = max(minTileSize.width, min(frame.width, containerSize.width - clampedX))
        let clampedHeight = max(minTileSize.height, min(frame.height, containerSize.height - clampedY))

        layout.x = clampedX / max(containerSize.width, 1)
        layout.y = clampedY / max(containerSize.height, 1)
        layout.width = clampedWidth / max(containerSize.width, 1)
        layout.height = clampedHeight / max(containerSize.height, 1)
    }

    private func snap(_ value: CGFloat, step: CGFloat) -> CGFloat {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }
}
