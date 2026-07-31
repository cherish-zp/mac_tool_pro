import Foundation

/// Central registry of all available tools. Add new tools here in `init`.
public final class ToolRegistry {
    public static let shared = ToolRegistry()

    public let tools: [Tool]

    private init() {
        tools = [
            CopyPathTool()
        ]
    }

    public func tool(for id: String) -> Tool? {
        tools.first { $0.id == id }
    }
}
