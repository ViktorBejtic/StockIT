
import SwiftUI

struct ItemsListCellView: View {
    @EnvironmentObject var session: UserSession
    @State private var locationName: String = ""
    @ObservedObject var VM: ItemsViewModel
    let location: Location
    let item: Item

    var body: some View {
        HStack(spacing: 14) {
            if item.attachments.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("noImageLabel")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 80, height: 80)
                .background(
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                TabView {
                    ForEach(item.attachments) { attachment in
                        SecureKFImage(urlString: attachment.link)
                            .frame(width: 80, height: 80)
                            .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.forText)
                    .lineLimit(1)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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
                } else if !item.categories.isEmpty {
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
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if location.id == -1 {
                VM.getLocationName(locationId: item.locationId) { name in
                    locationName = name
                }
            }
        }
    }
}
