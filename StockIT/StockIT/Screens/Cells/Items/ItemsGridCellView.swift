
import SwiftUI

struct ItemsGridCellView: View {
    @EnvironmentObject var session: UserSession
    @State private var locationName: String = ""
    @ObservedObject var VM: ItemsViewModel
    let location: Location
    let item: Item

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if item.attachments.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("noImageLabel")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .background(
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            } else {
                TabView {
                    ForEach(item.attachments, id: \.fileId) { attachment in
                        SecureKFImage(urlString: attachment.link)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
            }

            Text(ItemStatus(rawValue: item.status)?.displayName ?? LocalizedStringKey(item.status))
                .font(.system(size: 9, weight: .bold))
                .textCase(.uppercase)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(8)

            VStack {
                Spacer()
                HStack {
                    Text(item.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.forText)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
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
