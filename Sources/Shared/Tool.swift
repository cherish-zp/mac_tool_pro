import AppKit

/// A single small tool exposed through the Finder context menu and the menu bar app.
/// Conform to this protocol to add a new tool, then register it in `ToolRegistry`.
public protocol Tool: AnyObject {
    /// Stable, unique identifier persisted in user config (e.g. "copy-path").
    var id: String { get }
    /// Label shown in menus.
    var title: String { get }
    /// Optional icon shown next to the menu item.
    var image: NSImage? { get }
    /// Whether the tool applies to the given selection. Returning false hides it.
    func canPerform(on urls: [URL]) -> Bool
    /// Run the tool against the given selection.
    func perform(on urls: [URL])
}

public extension Tool {
    var image: NSImage? { nil }
    func canPerform(on urls: [URL]) -> Bool { !urls.isEmpty }
}
