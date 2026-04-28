import SwiftUI
import AppKit

extension Color {
    init?(hex: String) {
        if hex == "AccentColor" { return nil }
        let r, g, b: Double
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        guard hexSanitized.count == 6 else { return nil }
        let scanner = Scanner(string: hexSanitized)
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return nil }
        r = Double((rgb >> 16) & 0xFF) / 255.0
        g = Double((rgb >> 8) & 0xFF) / 255.0
        b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let nsColor = NSColor(self)
        let converted = nsColor.usingColorSpace(.sRGB)
            ?? nsColor.usingColorSpace(.displayP3)
            ?? nsColor.usingColorSpace(.deviceRGB)
            ?? nsColor.usingColorSpace(.genericRGB)
        var rC: CGFloat = 0, gC: CGFloat = 0, bC: CGFloat = 0, aC: CGFloat = 0
        if let c = converted {
            c.getRed(&rC, green: &gC, blue: &bC, alpha: &aC)
        } else {
            nsColor.getRed(&rC, green: &gC, blue: &bC, alpha: &aC)
        }
        let r = max(0, min(255, Int((rC * 255).rounded())))
        let g = max(0, min(255, Int((gC * 255).rounded())))
        let b = max(0, min(255, Int((bC * 255).rounded())))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension String {
    var nilIfBlank: String? {
        let clean = trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }
}
