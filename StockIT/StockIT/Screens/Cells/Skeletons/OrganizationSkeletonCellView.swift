import SwiftUI
import SkeletonUI

struct OrganizationSkeletonCellView: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 56, height: 56)
                .skeleton(
                    with: true,
                    animation: .pulse(),
                    appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                    shape: .rounded(.radius(14))
                )

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 140, height: 14)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 200, height: 11)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 11)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }
}
