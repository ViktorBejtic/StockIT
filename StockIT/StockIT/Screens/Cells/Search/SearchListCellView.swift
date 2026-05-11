import SwiftUI
import Kingfisher

struct SearchListCellView: View {
    @EnvironmentObject var session: UserSession
    @State private var locationName: String = ""
    @State private var organizationName: String = ""

    @ObservedObject var VM: SearchViewModel

    let showOrganizationName: Bool
    let showLocationName: Bool
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            if item.attachments.isEmpty {
                ZStack {
                    LinearGradient(
                        colors: [Color(.systemGray5), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22))
                        .foregroundStyle(.gray.opacity(0.4))
                }
                .frame(width: 80, height: 80)
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

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.forText)
                    .lineLimit(1)

                if showOrganizationName {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.caption2)
                            .foregroundStyle(.fiitPrimary)
                        Text(organizationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if showLocationName {
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

                if !showOrganizationName && !showLocationName && !item.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.categories) { category in
                                Text(category.name)
                                    .font(.caption2)
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

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
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
