import SwiftUI
import SkeletonUI

struct DashboardItemSkeletonCellView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 140)
                .skeleton(
                    with: true,
                    animation: .pulse(),
                    appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                    shape: .rectangle
                )

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 10)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 10)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 190)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
