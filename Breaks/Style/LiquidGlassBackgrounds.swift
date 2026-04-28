import SwiftUI

extension View {
    /// Flat low-opacity card background that reads cleanly on top of the
    /// system Liquid Glass popover backing.
    func glassCard(tint: Color = .clear, cornerRadius: CGFloat = 8) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint == .clear ? Color.secondary.opacity(0.08) : tint.opacity(0.10))
        )
    }
}

struct LiquidGlassPopoverBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(in: Rectangle())
        } else {
            content.background(.ultraThinMaterial)
        }
    }
}
