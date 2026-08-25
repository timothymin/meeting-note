import AppKit
import SwiftUI

enum AppDesign {
    static let popoverWidth: CGFloat = 320
    static let cardRadius: CGFloat = 10
    static let cardBackground = Color.primary.opacity(0.035)
    static let cardBorder = Color.primary.opacity(0.09)
    static let mutedBackground = Color.primary.opacity(0.055)
}

struct VibrancyBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        let effect = NSVisualEffectView()
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.isEmphasized = true
        effect.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(effect)

        let tint = NSView()
        tint.wantsLayer = true
        tint.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tint)
        updateTint(tint)

        NSLayoutConstraint.activate([
            effect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            effect.topAnchor.constraint(equalTo: container.topAnchor),
            effect.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            tint.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tint.topAnchor.constraint(equalTo: container.topAnchor),
            tint.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let tint = nsView.subviews.last { updateTint(tint) }
    }

    private func updateTint(_ view: NSView) {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        view.layer?.backgroundColor = (isDark
            ? NSColor.black.withAlphaComponent(0.24)
            : NSColor.white.withAlphaComponent(0.42)).cgColor
    }
}

struct AppCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.cardRadius, style: .continuous)
                    .fill(AppDesign.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cardRadius, style: .continuous)
                    .stroke(AppDesign.cardBorder, lineWidth: 1)
            )
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.13)))
    }
}
