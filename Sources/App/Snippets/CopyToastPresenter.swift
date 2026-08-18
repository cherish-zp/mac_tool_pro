import AppKit

/// 复制成功 Toast：毛玻璃 HUD，苹果风淡入淡出，菜单栏下方居中。
final class CopyToastPresenter: NSObject {

    static let shared = CopyToastPresenter()

    private var panel: NSPanel?
    private var hideWorkItem: DispatchWorkItem?
    private var generation = 0

    private let spec = CopyToastSpec.self

    func show() {
        DispatchQueue.main.async { [weak self] in
            self?.present()
        }
    }

    private func present() {
        generation += 1
        let currentGeneration = generation
        hideWorkItem?.cancel()
        hideWorkItem = nil

        let toastPanel = panel ?? makePanel()
        panel = toastPanel
        position(toastPanel)

        toastPanel.alphaValue = 0
        toastPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = spec.fadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            toastPanel.animator().alphaValue = 1
        })

        let item = DispatchWorkItem { [weak self] in
            guard let self = self, self.generation == currentGeneration else { return }
            self.dismiss(toastPanel)
        }
        hideWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + spec.fadeInDuration + spec.visibleDuration, execute: item)
    }

    private func dismiss(_ toastPanel: NSPanel) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = spec.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            toastPanel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self = self, self.panel === toastPanel, toastPanel.alphaValue == 0 else { return }
            toastPanel.orderOut(nil)
        })
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 128, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        panel.hidesOnDeactivate = false

        let visual = NSVisualEffectView()
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.wantsLayer = true
        visual.layer?.cornerRadius = CopyToastSpec.cornerRadius
        visual.layer?.masksToBounds = true
        visual.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = visual

        let symbol = NSImage(
            systemSymbolName: CopyToastSpec.symbolName,
            accessibilityDescription: CopyToastSpec.successMessage
        ) ?? NSImage()
        let icon = NSImageView(image: symbol)
        icon.contentTintColor = .controlAccentColor
        icon.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(icon)

        let label = NSTextField(labelWithString: CopyToastSpec.successMessage)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        visual.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: visual.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: visual.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 7),
            label.centerYAnchor.constraint(equalTo: visual.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: visual.trailingAnchor, constant: -14),
        ])

        return panel
    }

    private func position(_ toastPanel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - toastPanel.frame.width / 2,
            y: visible.maxY - toastPanel.frame.height - CopyToastSpec.topGap
        )
        toastPanel.setFrameOrigin(origin)
    }
}
