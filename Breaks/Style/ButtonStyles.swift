import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.94
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct HapticPrimaryButtonStyle: ButtonStyle {
    var tint: Color
    var pulse: Bool = false
    @State private var pulsing = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint)
                    .shadow(color: tint.opacity(configuration.isPressed ? 0.45 : 0.28),
                            radius: configuration.isPressed ? 10 : 6,
                            y: configuration.isPressed ? 3 : 2)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.92 : (pulsing ? 1.04 : 1.0))
            .animation(.spring(response: 0.18, dampingFraction: 0.55), value: configuration.isPressed)
            .animation(.spring(response: 0.32, dampingFraction: 0.62), value: pulsing)
            .onChange(of: configuration.isPressed) { pressed in
                if !pressed {
                    pulsing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { pulsing = false }
                }
            }
    }
}

struct ToolbarIconStyle: ButtonStyle {
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(hovering ? 0.14 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.15), value: hovering)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
