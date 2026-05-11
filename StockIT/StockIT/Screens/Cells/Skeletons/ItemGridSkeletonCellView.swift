
import SwiftUI
import SkeletonUI

struct ItemGridSkeletonCellView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .skeleton(
                    with: true,
                    animation: .pulse(),
                    appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                    shape: .rounded(.radius(16))
                )
                .aspectRatio(1, contentMode: .fit)

            VStack {
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 16)
                        .skeleton(
                            with: true,
                            animation: .pulse(),
                            appearance: .solid(color: .gray.opacity(0.15), background: .clear),
                            shape: .capsule
                        )
                        .padding(8)
                }
                Spacer()
            }

            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: 14)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )
                    .padding(.trailing, 24)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
