import AppKit
import UTUVODropCore

/// All geometry is based on the chosen screen's visible frame, including negative origins.
enum ShelfLayout {
    enum Edge { case left, right }
    static let collapsedWidth: CGFloat = 136
    static let collapsedHeight: CGFloat = 144
    static let thoughtGap: CGFloat = 48
    static let expandedWidth: CGFloat = 340
    static let itemHeight: CGFloat = 62

    static func frame(in visible: NSRect, edge: Edge, expanded: Bool, count: Int) -> NSRect {
        let inset = min(8, max(0, min(visible.width, visible.height) / 4))
        let width = min(expanded ? expandedWidth : collapsedWidth, max(1, visible.width - 2 * inset))
        let height = min(expanded ? collapsedHeight + thoughtGap + (count == 0 ? 176 : min(422, 156 + CGFloat(count) * itemHeight)) : collapsedHeight,
                         max(1, visible.height - 2 * inset))
        return NSRect(x: edge == .right ? visible.maxX - width : visible.minX,
                      y: max(visible.minY + inset, min(visible.midY - collapsedHeight / 2, visible.maxY - inset - height)),
                      width: width, height: height)
    }
}

final class ShelfWindowController: NSWindowController {
    let viewModel: ShelfViewModel
    let content: ShelfContentView
    private(set) var edge: ShelfLayout.Edge = .right
    private var chosenScreen: NSScreen?
    private var screenObserver: NSObjectProtocol?

    init(viewModel: ShelfViewModel = ShelfViewModel()) {
        self.viewModel = viewModel
        content = ShelfContentView(viewModel: viewModel)
        let panel = NSPanel(contentRect: content.frame,
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.title = "UTUVO Drop"
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView = content
        super.init(window: panel)
        chosenScreen = NSScreen.main ?? NSScreen.screens.first
        content.onSizeChanged = { [weak self] in self?.position() }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.position() }
        position()
    }

    required init?(coder: NSCoder) { fatalError("not used") }
    deinit { if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) } }

    func reload() { content.reload(); position() }
    func cycleEdge() { edge = edge == .right ? .left : .right; position() }
    func showShelf() { position(); window?.orderFrontRegardless() }

    func position() {
        let screens = NSScreen.screens
        // Keep the original monitor; use a remaining monitor after unplug/reconfiguration.
        let oldID = chosenScreen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        chosenScreen = screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber) == oldID
        } ?? NSScreen.main ?? screens.first
        guard let screen = chosenScreen else { return }
        content.petOnLeft = edge == .left
        window?.setFrame(ShelfLayout.frame(in: screen.visibleFrame, edge: edge,
                                           expanded: content.isExpanded, count: viewModel.allItems.count),
                         display: true)
        content.needsLayout = true
    }
}
