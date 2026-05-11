
import SwiftUI
import SkeletonUI

struct ItemListSkeletonCellView: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 80, height: 80)
                .skeleton(
                    with: true,
                    animation: .pulse(),
                    appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                    shape: .rounded(.radius(12))
                )

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .padding(.trailing, 40)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.15), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
                    .padding(.trailing, 20)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.1), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { _ in
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 52, height: 18)
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.1), background: .clear),
                                shape: .capsule
                            )
                    }
                }
            }

            Spacer(minLength: 4)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 8, height: 14)
                .skeleton(
                    with: true,
                    animation: .pulse(),
                    appearance: .solid(color: .gray.opacity(0.1), background: .clear),
                    shape: .rounded(.radius(2))
                )
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
