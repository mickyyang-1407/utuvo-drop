import AppKit
import UTUVODropCore

final class ShelfItemRow: NSView {
    let item: ShelfItem
    let iconView = NSImageView()
    let nameLabel = NSTextField(labelWithString: "")
    let metaLabel = NSTextField(labelWithString: "")
    let removeButton = NSButton(title: "", target: nil, action: nil)
    private(set) var status: ShelfItemStatus = .ok
    var onDragRequested: ((URL, NSEvent) -> Void)?
    var onRemoveRequested: ((URL) -> Void)?
    private var mouseDownLocation: NSPoint?

    init(item: ShelfItem) {
        self.item = item
        super.init(frame: NSRect(x: 0, y: 0, width: 280, height: ShelfLayout.itemHeight))
        iconView.image = NSWorkspace.shared.icon(forFile: item.url.path)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        nameLabel.stringValue = item.displayName
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.lineBreakMode = .byTruncatingMiddle
        metaLabel.font = .systemFont(ofSize: 11)
        metaLabel.lineBreakMode = .byTruncatingMiddle
        removeButton.isBordered = false
        removeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        removeButton.symbolConfiguration = .init(pointSize: 10, weight: .medium)
        removeButton.contentTintColor = .secondaryLabelColor
        removeButton.toolTip = "Remove from shelf. Keep the original file."
        removeButton.target = self
        removeButton.action = #selector(removeReference)
        removeButton.setAccessibilityLabel("Remove \(item.displayName) reference")
        [iconView, nameLabel, metaLabel, removeButton].forEach { addSubview($0) }
        toolTip = item.url.path
        refreshStatus()
    }
    required init?(coder: NSCoder) { fatalError("not used") }
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func layout() {
        super.layout()
        iconView.frame = NSRect(x: 10, y: 13, width: 36, height: 36)
        nameLabel.frame = NSRect(x: 56, y: 11, width: max(1, bounds.width - 88), height: 20)
        metaLabel.frame = NSRect(x: 56, y: 33, width: max(1, bounds.width - 88), height: 17)
        removeButton.frame = NSRect(x: max(0, bounds.width - 31), y: 18, width: 24, height: 26)
    }
    // Let the row receive drags over its image/labels, but keep the remove button independent.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        return hit === removeButton || hit.isDescendant(of: removeButton) ? hit : self
    }
    func refreshStatus() {
        status = ShelfModel.defaultProbe(item.url)
        switch status {
        case .ok:
            let values = try? item.url.resourceValues(forKeys: [.isDirectoryKey])
            let parent = item.url.deletingLastPathComponent().lastPathComponent
            if values?.isDirectory == true { metaLabel.stringValue = parent + " · 資料夾" }
            else if let size = ShelfModel.byteSizeIfRegularFile(item.url) {
                metaLabel.stringValue = parent + " · " + ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            } else { metaLabel.stringValue = parent }
        case .missing:
            metaLabel.stringValue = "Missing — remove or re-drop"
        case .unreadable:
            metaLabel.stringValue = "Unreadable — cannot drag"
        }
        updateMetaColor()
    }
    private func updateMetaColor() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            metaLabel.textColor = status == .ok ? .labelColor.withAlphaComponent(0.75) : .systemRed
        }
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateMetaColor()
    }
    @objc func removeReference() { onRemoveRequested?(item.url) }
    override func resetCursorRects() {
        addCursorRect(NSRect(x: 0, y: 0, width: max(1, bounds.width - 32), height: bounds.height), cursor: .openHand)
    }
    override func mouseDown(with event: NSEvent) { mouseDownLocation = event.locationInWindow }
    override func mouseDragged(with event: NSEvent) {
        guard let start = mouseDownLocation else { return }
        let point = event.locationInWindow
        guard hypot(point.x - start.x, point.y - start.y) >= 4 else { return }
        mouseDownLocation = nil
        onDragRequested?(item.url, event)
    }
    override func mouseUp(with event: NSEvent) { mouseDownLocation = nil }
}
