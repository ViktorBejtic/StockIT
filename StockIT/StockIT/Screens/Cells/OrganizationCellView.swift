import SwiftUI

struct OrganizationCellView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: OrganizationsViewModel
    @State private var showDeleteConfirmation = false
    let organization: Organization

    private var initials: String {
        let words = organization.name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(organization.name.prefix(2)).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.fiitPrimary, Color.fiitPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Text(initials)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(organization.name)
                    .font(.headline)
                    .foregroundStyle(.forText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.fiitPrimary.opacity(0.7))
                    Text("\(organization.street) \(organization.streetNumber), \(organization.city)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !organization.description.isEmpty {
                    Text(organization.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.forText)
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }
}
