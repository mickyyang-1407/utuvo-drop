import AppKit
import AVFAudio

/// Opt-in local design fixtures; never touches a user's shelf or recordings.
@MainActor final class PreviewHarness {
    let directory: URL
    let files: [URL]

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("utuvo-drop-preview-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let samples = directory.appendingPathComponent("Drop samples")
        try FileManager.default.createDirectory(at: samples, withIntermediateDirectories: true)
        let notes = samples.appendingPathComponent("Session notes.txt")
        try Data(String(repeating: "A local sample file for the Drop preview.\n", count: 32).utf8).write(to: notes)
        let folder = samples.appendingPathComponent("Artwork")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let audio = samples.appendingPathComponent("Room tone.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 96000)!
        buffer.frameLength = 96000
        buffer.floatChannelData![0].initialize(repeating: 0, count: 96000)
        let file = try AVAudioFile(forWriting: audio, settings: format.settings)
        try file.write(from: buffer)
        files = [audio, notes, folder]
    }

    func seed(_ controller: ShelfWindowController) {
        controller.viewModel.insert(files)
        controller.reload()
    }

    func cleanup() { try? FileManager.default.removeItem(at: directory) }

    func render(_ controller: ShelfWindowController, to output: URL) async throws {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        guard let window = controller.window else { return }
        controller.content.tail.reduceMotionOverride = true
        defer { controller.content.tail.reduceMotionOverride = nil }
        window.appearance = NSAppearance(named: .aqua)
        controller.content.clearShelf()
        controller.content.tuckAwayIfIdle(animated: false)
        try await capture(controller, to: output.appendingPathComponent("drop-tail-empty.png"))
        seed(controller)
        try await capture(controller, to: output.appendingPathComponent("drop-tail-full.png"))
        controller.cycleEdge()
        try await capture(controller, to: output.appendingPathComponent("drop-tail-left.png"))
        controller.cycleEdge()
        controller.content.revealCat(animated: false)
        try await capture(controller, to: output.appendingPathComponent("drop-cat-small.png"))
        controller.content.cat.update(count: files.count, mood: .hungry)
        try await capture(controller, to: output.appendingPathComponent("drop-cat-mouth.png"))
        controller.content.cat.update(count: files.count, mood: .idle)
        controller.content.setDetailsVisible(true)
        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            window.appearance = NSAppearance(named: appearance)
            seed(controller)
            try await capture(controller, to: output.appendingPathComponent("drop-cat-list-\(name).png"))
        }
        controller.content.clearShelf()
        window.appearance = NSAppearance(named: .aqua)
        controller.content.setDetailsVisible(true)
        try await capture(controller, to: output.appendingPathComponent("drop-cat-empty-list.png"))
        // Exercise the floating placement near the top edge with owned fixture files.
        seed(controller)
        controller.content.setDetailsVisible(true)
        if let visible = controller.window?.screen?.visibleFrame {
            let target = NSPoint(x: visible.midX - ShelfLayout.collapsedWidth / 2,
                                 y: visible.maxY - ShelfLayout.collapsedHeight - 8)
            controller.move(by: NSPoint(x: target.x - controller.petOrigin.x, y: target.y - controller.petOrigin.y))
            controller.finishMoving()
            try await capture(controller, to: output.appendingPathComponent("drop-cat-top.png"))
        }
    }

    private func capture(_ controller: ShelfWindowController, to url: URL) async throws {
        guard let window = controller.window else { return }
        // A glass-only window capture omits its backdrop. Use an owned neutral
        // window behind the shelf so the screen composite contains no other app.
        let backdrop = NSWindow(contentRect: window.frame.insetBy(dx: -8, dy: -8),
            styleMask: .borderless, backing: .buffered, defer: false)
        backdrop.isReleasedWhenClosed = false
        let dark = window.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        backdrop.backgroundColor = dark
            ? NSColor(calibratedWhite: 0.10, alpha: 1)
            : NSColor(calibratedWhite: 0.94, alpha: 1)
        // Cover other floating windows too; bring our preview above this owned backdrop below.
        backdrop.level = window.level
        backdrop.orderFrontRegardless()
        defer { backdrop.orderOut(nil) }
        window.contentView?.layoutSubtreeIfNeeded()
        window.orderFrontRegardless()
        try await Task.sleep(for: .milliseconds(500))
        // Native glass needs the actual WindowServer composite, not cacheDisplay.
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        let frame = window.frame
        let screenTop = NSScreen.screens.first?.frame.maxY ?? frame.maxY
        let rect = "\(Int(frame.minX)),\(Int(screenTop - frame.maxY)),\(Int(frame.width)),\(Int(frame.height))"
        capture.arguments = ["-x", "-R", rect, url.path]
        try capture.run()
        capture.waitUntilExit()
        guard capture.terminationStatus == 0 else {
            throw NSError(domain: "DropPreview", code: Int(capture.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Window capture failed; check Screen Recording permission."])
        }
    }
}
