// NotifyDaemon — persistent banner renderer using SwiftUI Liquid Glass
// (`.glassEffect()`) on macOS Tahoe (26+). Listens on a Unix domain socket
// at ~/.notifyd.sock and renders custom banners via NSWindow + NSHostingView.
// Does NOT use UserNotifications framework, so no permissions, no ncprefs,
// no notarization gating, no Focus/mirroring DnD suppression. Just windows.
//
// Wire protocol: one JSON object per line, newline-terminated. Example:
//   {"action":"show","title":"🔊 Audio","body":"BE-RCA",
//    "icon":"/path/to/icon.png","duration":3.0,"sound":"Glass"}
//   {"action":"clear"}
//
// Run via launchd (~/Library/LaunchAgents/com.servitola.notifyd.plist).
//
// Build:
//   swiftc -O -framework AppKit -framework SwiftUI \
//       -o NotifyDaemon NotifyDaemon.swift

import AppKit
import SwiftUI
import Foundation
import Darwin

// MARK: - wire protocol

struct BannerSpec: Decodable {
    let action: String
    let title: String?
    let body: String?
    let icon: String?
    let duration: Double?
    let sound: String?
    let tint: String?         // "green" / "red" / "#22cc88" / nil → neutral
    let symbol: String?       // SF Symbol name e.g. "hifispeaker.2.fill"
    let symbolColor: String?  // optional tint just for the SF Symbol
    let animate: Bool?        // animate symbol (repeating variableColor)
}

// Parse "green" / "#22cc88" / "rgb(34,204,136)" → SwiftUI Color.
func parseColor(_ raw: String?) -> Color? {
    guard let raw = raw?.trimmingCharacters(in: .whitespaces).lowercased(),
          !raw.isEmpty else { return nil }
    let named: [String: Color] = [
        "red": .red, "orange": .orange, "yellow": .yellow, "green": .green,
        "mint": .mint, "teal": .teal, "cyan": .cyan, "blue": .blue,
        "indigo": .indigo, "purple": .purple, "pink": .pink, "brown": .brown,
        "gray": .gray, "white": .white, "black": .black,
    ]
    if let c = named[raw] { return c }
    if raw.hasPrefix("#") {
        let hex = String(raw.dropFirst())
        if hex.count == 6, let v = UInt32(hex, radix: 16) {
            let r = Double((v >> 16) & 0xff) / 255
            let g = Double((v >> 8) & 0xff) / 255
            let b = Double(v & 0xff) / 255
            return Color(red: r, green: g, blue: b)
        }
    }
    return nil
}

// MARK: - SwiftUI banner view (Liquid Glass)

struct BannerView: View {
    let title: String
    let message: String
    let iconPath: String?
    let tint: Color?
    let symbolName: String?
    let symbolColor: Color?
    let symbolAnimate: Bool

    // Tahoe glass with strong tint when colored, neutral otherwise.
    // `.clear` is the thinner Tahoe Liquid Glass variant — significantly
    // more transparent than `.regular`, lets background apps show through.
    private var glassStyle: Glass {
        if let tint { return .clear.tint(tint) }
        return .clear
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            iconView
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 440, height: 96, alignment: .leading)
        // Subtle colored backdrop under the glass — just enough hue for the
        // banner to read as "this kind of event" without shouting.
        .background {
            if let tint {
                RoundedRectangle(cornerRadius: 28)
                    .fill(tint.opacity(0.05))
            }
        }
        .glassEffect(glassStyle, in: RoundedRectangle(cornerRadius: 28))
        // Soft glossy reflection band along the top — fakes light hitting
        // the curved upper edge of glass. Clipped by the same rounded
        // rectangle so it never overhangs and never produces a visible
        // second-edge artifact next to the glass material's own border.
        .overlay {
            LinearGradient(
                colors: [.white.opacity(0.22), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: 36, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .allowsHitTesting(false)
            .blendMode(.plusLighter)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let name = symbolName {
            // SF Symbol — supports built-in motion via `.symbolEffect`.
            // `.variableColor.iterative` cycles the symbol's layered
            // tinting (e.g. speaker waves pulsing outwards). Perfect for
            // audio/status icons in Tahoe.
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill((symbolColor ?? tint ?? .accentColor).gradient)
                Image(systemName: name)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
                    .modifier(SymbolAnimationModifier(active: symbolAnimate))
            }
            .frame(width: 56, height: 56)
        } else if let path = iconPath,
                  FileManager.default.fileExists(atPath: path),
                  let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .interpolation(.high)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            // Fallback colored badge when nothing specified — keeps banner
            // visually balanced instead of empty space on the left.
            RoundedRectangle(cornerRadius: 14)
                .fill((tint ?? .accentColor).gradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }
}

// Conditional `.symbolEffect` — only applied when animation is requested.
// Lives in its own ViewModifier because conditional view modifiers don't
// play well with `.symbolEffect` directly inside ZStack.
struct SymbolAnimationModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            content.symbolEffect(.variableColor.iterative.reversing,
                                 options: .repeat(.continuous))
        } else {
            content
        }
    }
}

// MARK: - banner window manager

@MainActor
final class BannerStack {
    static let shared = BannerStack()

    private var windows: [NSWindow] = []
    private let bannerWidth: CGFloat = 440
    private let bannerHeight: CGFloat = 96
    private let margin: CGFloat = 18
    private let gap: CGFloat = 14

    func show(_ spec: BannerSpec) {
        FileHandle.standardError.write("show called: title=\(spec.title ?? "nil") body=\(spec.body ?? "nil")\n".data(using: .utf8)!)
        guard spec.title != nil || spec.body != nil else {
            FileHandle.standardError.write("  → skipped: no title or body\n".data(using: .utf8)!)
            return
        }

        let view = BannerView(
            title: spec.title ?? "",
            message: spec.body ?? "",
            iconPath: spec.icon,
            tint: parseColor(spec.tint),
            symbolName: spec.symbol,
            symbolColor: parseColor(spec.symbolColor),
            symbolAnimate: spec.animate ?? false
        )

        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(x: 0, y: 0, width: bannerWidth, height: bannerHeight)

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: bannerWidth, height: bannerHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = false

        // Click-to-dismiss anywhere on the banner.
        let click = NSClickGestureRecognizer(target: self,
                                              action: #selector(handleClick(_:)))
        hosting.view.addGestureRecognizer(click)

        // Final position (top-right, stacked).
        let endOrigin = origin(forIndex: windows.count)
        let startOrigin = NSPoint(x: endOrigin.x + bannerWidth + 40, y: endOrigin.y)
        window.setFrameOrigin(startOrigin)
        window.alphaValue = 1
        window.orderFrontRegardless()
        windows.append(window)
        FileHandle.standardError.write("  start \(startOrigin) → end \(endOrigin)\n".data(using: .utf8)!)

        // Manual 60fps slide. NSWindow.setFrame(animate:) silently no-ops
        // here and animator().setFrameOrigin needs an active animation
        // proxy — a hand-rolled timer with an easeOutCubic curve is the
        // reliable path.
        animatePosition(window: window, from: startOrigin, to: endOrigin, duration: 0.4)

        if let soundName = spec.sound, let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        }

        let duration = max(0.5, spec.duration ?? 3.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak window] in
            guard let self, let window else { return }
            self.dismiss(window)
        }
    }

    @objc private func handleClick(_ recognizer: NSClickGestureRecognizer) {
        if let win = recognizer.view?.window { dismiss(win) }
    }

    func clearAll() {
        for w in windows { dismiss(w) }
    }

    private func dismiss(_ window: NSWindow) {
        let from = window.frame.origin
        let to = NSPoint(x: from.x + bannerWidth + margin * 2, y: from.y)
        animatePosition(window: window, from: from, to: to, duration: 0.28)
        // Fade and unmount after the slide-out completes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self, weak window] in
            guard let self, let window else { return }
            window.orderOut(nil)
            self.windows.removeAll { $0 === window }
            self.relayout()
        }
    }

    private func relayout() {
        for (i, win) in windows.enumerated() {
            let target = origin(forIndex: i)
            animatePosition(window: win, from: win.frame.origin, to: target,
                            duration: 0.25)
        }
    }

    // Hand-rolled position animation — 60 fps, easeOutCubic curve.
    // Reliable replacement for NSWindow.setFrame(animate:) and
    // window.animator().setFrameOrigin which silently no-op for our setup.
    private func animatePosition(window: NSWindow,
                                  from: NSPoint, to: NSPoint,
                                  duration: TimeInterval) {
        let start = Date()
        let dx = to.x - from.x
        let dy = to.y - from.y
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(start)
            let t = min(1.0, elapsed / duration)
            let eased = 1 - pow(1 - t, 3)  // easeOutCubic
            let x = from.x + dx * CGFloat(eased)
            let y = from.y + dy * CGFloat(eased)
            window.setFrameOrigin(NSPoint(x: x, y: y))
            if t >= 1.0 { timer.invalidate() }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    private func origin(forIndex index: Int) -> NSPoint {
        guard let screen = NSScreen.main else { return .zero }
        let visible = screen.visibleFrame
        let x = visible.maxX - bannerWidth - margin
        let y = visible.maxY - bannerHeight - margin - CGFloat(index) * (bannerHeight + gap)
        return NSPoint(x: x, y: y)
    }
}

// MARK: - Unix socket server

final class SocketServer {
    private let path: String
    private var fd: Int32 = -1
    private let acceptQueue  = DispatchQueue(label: "notifyd.accept",  qos: .userInitiated)
    private let handlerQueue = DispatchQueue(label: "notifyd.handler", qos: .userInitiated,
                                              attributes: .concurrent)

    init(path: String) { self.path = path }

    func start() throws {
        unlink(path)

        fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw NSError(domain: "socket", code: Int(errno)) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        path.withCString { src in
            withUnsafeMutablePointer(to: &addr.sun_path) {
                $0.withMemoryRebound(to: CChar.self, capacity: 104) { dst in
                    _ = strlcpy(dst, src, 104)
                }
            }
        }

        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, len)
            }
        }
        guard bound == 0 else {
            close(fd)
            throw NSError(domain: "bind", code: Int(errno))
        }
        chmod(path, 0o600)
        guard listen(fd, 16) == 0 else {
            close(fd)
            throw NSError(domain: "listen", code: Int(errno))
        }

        acceptQueue.async { [weak self] in self?.acceptLoop() }
        FileHandle.standardError.write("notifyd: listening on \(path)\n".data(using: .utf8)!)
    }

    private func acceptLoop() {
        while true {
            let client = accept(fd, nil, nil)
            if client < 0 {
                if errno == EINTR { continue }
                FileHandle.standardError.write("accept error \(errno)\n".data(using: .utf8)!)
                break
            }
            handlerQueue.async { [weak self] in self?.handle(client: client) }
        }
    }

    private func handle(client: Int32) {
        defer { close(client) }
        var buffer = Data()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = read(client, &chunk, chunk.count)
            if n <= 0 { break }
            buffer.append(chunk, count: n)
            // Process newline-delimited JSON.
            while let nl = buffer.firstIndex(of: 0x0A) {
                let line = buffer.prefix(upTo: nl)
                buffer.removeSubrange(0...nl)
                guard !line.isEmpty else { continue }
                dispatch(line: line)
            }
        }
        if !buffer.isEmpty { dispatch(line: buffer) }
    }

    private func dispatch(line: Data) {
        FileHandle.standardError.write("dispatch: \(line.count) bytes\n".data(using: .utf8)!)
        do {
            let spec = try JSONDecoder().decode(BannerSpec.self, from: line)
            FileHandle.standardError.write("  decoded: action=\(spec.action)\n".data(using: .utf8)!)
            Task { @MainActor in
                FileHandle.standardError.write("  on main: dispatching \(spec.action)\n".data(using: .utf8)!)
                switch spec.action {
                case "show":  BannerStack.shared.show(spec)
                case "clear": BannerStack.shared.clearAll()
                default:      FileHandle.standardError.write("  unknown action: \(spec.action)\n".data(using: .utf8)!)
                }
            }
        } catch {
            FileHandle.standardError.write("bad json: \(error)\n".data(using: .utf8)!)
        }
    }
}

// MARK: - main

final class AppDelegate: NSObject, NSApplicationDelegate {
    var server: SocketServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let socketPath = "\(home)/.notifyd.sock"
        let server = SocketServer(path: socketPath)
        do {
            try server.start()
        } catch {
            FileHandle.standardError.write("failed to start socket: \(error)\n".data(using: .utf8)!)
            exit(1)
        }
        self.server = server
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no Dock icon, no menu bar
let delegate = AppDelegate()
app.delegate = delegate
app.run()
