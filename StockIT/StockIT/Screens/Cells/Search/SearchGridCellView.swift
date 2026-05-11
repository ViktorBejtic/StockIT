import SwiftUI

struct SearchGridCellView: View {
    @EnvironmentObject var session: UserSession
    @State private var locationName: String = ""
    @State private var organizationName: String = ""

    @ObservedObject var VM: SearchViewModel

    let showOrganizationName: Bool
    let showLocationName: Bool
    let item: Item

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fill)
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

            ZStack(alignment: .topTrailing) {
                Color.clear

                Text(ItemStatus(rawValue: item.status)?.displayName ?? LocalizedStringKey(item.status))
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .onAppear {
            loadNames()
        }
    }

    private func loadNames() {
        Task {
            if showOrganizationName {
                if let org = VM.allOrganizations.first(where: { $0.organizationId == item.organizationId }) {
                    self.organizationName = org.name
                } else {
                    self.organizationName = "Unknown Organization"
                }
            }
            if showLocationName {
                if let loc = VM.allLocations.first(where: { String($0.id) == item.locationId }) {
                    self.locationName = loc.name
                } else {
                    self.locationName = "Unknown Location"
                }
            }
        }
    }
}
