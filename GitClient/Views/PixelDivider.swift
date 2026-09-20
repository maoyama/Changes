import SwiftUI

struct PixelDivider: View {
    @Environment(\.pixelLength) private var pixelLength

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: pixelLength)
            .accessibilityHidden(true)
    }
}
