import AppKit
import UTUVODropCore

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var shelfController: ShelfWindowController?
    private var statusItem: NSStatusItem?
    private var smokeDirectory: URL?
    private var smokeFailed = false
    private var previewHarness: PreviewHarness?
    private let isSmoke = CommandLine.arguments.contains("--smoke-test")

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = ShelfWindowController()
        shelfController = controller
        controller.showShelf()
        installStatusItem()
        let args = CommandLine.arguments
        if args.contains("--preview") || args.contains("--render-preview") {
            do {
                let harness = try PreviewHarness()
                previewHarness = harness
                if let index = args.firstIndex(of: "--render-preview") {
                    guard args.count == index + 2 else { exit(2) }
                    Task { @MainActor in
                        do {
                            try await harness.render(controller, to: URL(fileURLWithPath: args[index + 1]))
                            NSApp.terminate(nil)
                        } catch {
                            harness.cleanup()
                            self.log("PREVIEW FAIL \(error)")
                            exit(2)
                        }
                    }
                } else { harness.seed(controller) }
            } catch { log("PREVIEW FAIL \(error)"); exit(2) }
            return
        }
        if isSmoke {
            log("SMOKE didFinishLaunching accessory=\(NSApp.activationPolicy() == .accessory)")
            DispatchQueue.main.async { [weak self] in self?.runSmoke() }
        }
    }

    private func log(_ message: String) {
        FileHandle.standardOutput.write(Data((message + "\n").utf8))
    }
    private func check(_ condition: Bool, _ name: String) throws {
        guard condition else { throw NSError(domain: "UTUVODropSmoke", code: 1,
                                             userInfo: [NSLocalizedDescriptionKey: name]) }
        log("SMOKE PASS \(name)")
    }

    private func runSmoke() {
        do {
            guard let controller = shelfController, let panel = controller.window else {
                throw NSError(domain: "UTUVODropSmoke", code: 2)
            }
            try check(panel.isVisible && panel is NSPanel, "visible native panel")
            let content = controller.content
            content.setHovered(false)
            try check(!content.isExpanded && controller.viewModel.isEmpty, "empty tiny target")
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent("utuvo-drop-smoke-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            smokeDirectory = dir
            let files = (0..<3).map { dir.appendingPathComponent("seed-\($0).txt") }
            for file in files { try Data("owned smoke seed\n".utf8).write(to: file) }
            let pb = NSPasteboard.withUniqueName()
            defer { pb.releaseGlobally() }
            try check(pb.writeObjects(files.map { $0 as NSURL }), "owned file URL pasteboard")
            try check(content.acceptFiles(from: pb) && controller.viewModel.allItems.count == 3, "seeded shelf count=3")
            panel.contentView?.layoutSubtreeIfNeeded()
            try check(content.isExpanded && panel.frame.width > ShelfLayout.collapsedWidth, "accepted drop automatically opens thought bubble")
            if let visible = panel.screen?.visibleFrame {
                try check(visible.contains(panel.frame), "panel fits screen")
            } else { try check(false, "screen available") }
            let urls = controller.viewModel.allItems.map(\.url)
            let items = content.draggingItems(for: urls)
            let out = NSPasteboard.withUniqueName()
            defer { out.releaseGlobally() }
            let writers = items.compactMap { $0.item as? NSPasteboardWriting }
            try check(writers.count == 3 && out.writeObjects(writers), "native drag writers count=3")
            try check(PasteboardFileURLReader().readFileURLs(from: out) == urls, "outbound file URL roundtrip")
            try FileManager.default.removeItem(at: files[0])
            try check(content.draggingItems(for: [urls[0]]).isEmpty && content.errorMessage != nil, "stale drag blocked")
            content.rowsByURL[urls[0]]?.removeReference()
            try check(controller.viewModel.allItems.count == 2, "remove reference")
            content.clearButton.performClick(nil)
            content.setHovered(false)
            try check(controller.viewModel.isEmpty && !content.isExpanded && panel.frame.width == ShelfLayout.collapsedWidth, "clear keeps cat target")
            try check(try Data(contentsOf: files[1]) == Data("owned smoke seed\n".utf8), "source bytes unchanged")
            log("SMOKE seeded=3 screens=\(NSScreen.screens.count) frame=\(panel.frame) PASS")
        } catch {
            smokeFailed = true
            log("SMOKE FAIL \(error)")
        }
        // Only the opt-in smoke run schedules a timer. Normal operation never polls.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            do {
                if let dir = self.smokeDirectory { try FileManager.default.removeItem(at: dir) }
                self.smokeDirectory = nil
                self.log("SMOKE cleanup=PASS timed-quit exit=\(self.smokeFailed ? 1 : 0)")
            } catch {
                self.smokeFailed = true
                self.log("SMOKE cleanup=FAIL \(error)")
            }
            if self.smokeFailed { exit(1) }
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        previewHarness?.cleanup()
        if let dir = smokeDirectory { try? FileManager.default.removeItem(at: dir) }
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        shelfController?.window?.orderOut(nil)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        shelfController?.showShelf()
        return true
    }
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "UTUVO Drop")
        item.button?.toolTip = "UTUVO Drop — file references only"
        let menu = NSMenu()
        for (title, action) in [("Show Shelf", #selector(showShelf)), ("Clear Shelf", #selector(clearShelf)),
                                 ("Move Shelf Edge", #selector(cycleEdge)), ("Quit UTUVO Drop", #selector(quit))] {
            let entry = NSMenuItem(title: title, action: action, keyEquivalent: title.hasPrefix("Quit") ? "q" : "")
            entry.target = self
            menu.addItem(entry)
        }
        item.menu = menu
        statusItem = item
    }
    @objc private func showShelf() { shelfController?.showShelf() }
    @objc private func clearShelf() { shelfController?.content.clearShelf() }
    @objc private func cycleEdge() { shelfController?.cycleEdge() }
    @objc private func quit() { NSApp.terminate(nil) }
}
