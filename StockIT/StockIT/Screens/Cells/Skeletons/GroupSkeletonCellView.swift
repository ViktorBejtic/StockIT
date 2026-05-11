import SwiftUI
import SkeletonUI

struct GroupSkeletonCellView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .circle
                    )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 14)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 12)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 70, height: 24)
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                                shape: .capsule
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 12)
                    .skeleton(
                        with: true,
                        animation: .pulse(),
                        appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                        shape: .rounded(.radius(4))
                    )

                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 30, height: 30)
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                                shape: .circle
                            )
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 100, height: 12)
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.2), background: .clear),
                                shape: .rounded(.radius(4))
                            )
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
