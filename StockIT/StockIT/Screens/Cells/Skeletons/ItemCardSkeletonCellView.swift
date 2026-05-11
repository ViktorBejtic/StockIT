
import SwiftUI
import SkeletonUI

struct ItemCardSkeletonCellView: View {
    let cardWidth = UIScreen.main.bounds.width - 32

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: cardWidth, height: cardWidth * 0.65)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rectangle
                    )

                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 20)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.15), background: .clear),
                        shape: .capsule
                    )
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 18)
                    .padding(.trailing, 80)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.15), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                    .padding(.trailing, 40)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.1), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 60, height: 20)
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.1), background: .clear),
                                shape: .capsule
                            )
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}
