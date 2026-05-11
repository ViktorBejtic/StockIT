import SwiftUI

struct DashboardItemCellView: View {
    @ObservedObject var VM: DashboardViewModel
    let item: Item

    var locationName: String {
        VM.locations.first(where: { $0.locationId == item.locationId })?.name ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if item.attachments.isEmpty {
                    ZStack {
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28))
                                .foregroundStyle(.gray.opacity(0.4))
                            Text("noImageLabel")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(height: 140)
                } else {
                    TabView {
                        ForEach(item.attachments) { attachment in
                            SecureKFImage(urlString: attachment.link)
                                .frame(height: 140)
                                .clipped()
                                .contentShape(Rectangle())
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 140)
                }

                Text(ItemStatus(rawValue: item.status)?.displayName ?? LocalizedStringKey(item.status))
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.fiitPrimary)
                    Text(locationName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let createdAt = item.createdAt?.relativeTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(createdAt)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
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
