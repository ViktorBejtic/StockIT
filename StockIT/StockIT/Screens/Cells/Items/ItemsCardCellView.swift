
import SwiftUI

struct ItemsCardCellView: View {
    @EnvironmentObject var session: UserSession
    @State private var locationName: String = ""
    @ObservedObject var VM: ItemsViewModel
    let location: Location
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                let cardWidth = UIScreen.main.bounds.width - 32
                if item.attachments.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text("noImageAvailableLabel")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(width: cardWidth, height: cardWidth * 0.65)
                    .background(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                } else {
                    TabView {
                        ForEach(item.attachments) { attachment in
                            SecureKFImage(urlString: attachment.link)
                                .frame(width: cardWidth, height: cardWidth * 0.65)
                                .clipped()
                                .contentShape(Rectangle())
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(width: cardWidth, height: cardWidth * 0.65)
                }

                Text(ItemStatus(rawValue: item.status)?.displayName ?? LocalizedStringKey(item.status))
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.forText)
                    .lineLimit(2)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !item.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.categories) { category in
                                Text(category.name)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.fiitPrimary.opacity(0.1))
                                    .foregroundStyle(.fiitPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if location.id == -1 {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.fiitPrimary)
                        Text(locationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .onAppear {
            if location.id == -1 {
                VM.getLocationName(locationId: item.locationId) { name in
                    locationName = name
                }
            }
        }
    }
}
