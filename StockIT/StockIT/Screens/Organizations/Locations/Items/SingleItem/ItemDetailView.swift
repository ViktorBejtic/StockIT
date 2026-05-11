import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: SingleItemViewModel

    @Binding var item: Item
    @Binding var activeID: String?
    @Binding var refreshFlag: Bool

    @State private var showArchiveAlert = false
    @State private var showUnarchiveAlert = false
    @State private var showDeleteAlert = false
    @State private var showEditItem = false

    @State private var organizationName: String = ""
    @State private var locationName: String = ""
    @State private var createdByName: String = ""
    @State private var editedByName: String = ""
    @State private var shownPopoverId: Int?

    private let userService = UserService()

    let maxWidth = UIScreen.main.bounds.width

    @State private var selectedImageIndex: Int = 0
    @State private var isShowingFullscreenGallery = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                imageSection

                infoCard

                locationCard

                categoriesCard

                attributesCard

                activityCard

                actionButtonsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            if let mainUser = session.mainUser {
                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "EDIT_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                    ($0.permissionName == "EDIT_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                }) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("editButton") { showEditItem.toggle() }
                            .tint(Color.fiitPrimary)
                    }
                }
            }
        }
        .navigationTitle("itemDetailTitle")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showEditItem) {
            NavigationStack {
                UpdateItemView(VM: VM, item: $item, refreshFlag: $refreshFlag)
                    .navigationBarBackButtonHidden()
            }
        }
        .alert("archiveItemConfirm", isPresented: $showArchiveAlert) {
            Button("archiveButton", role: .destructive) {
                VM.archiveItem(item: $item, refreshFlag: $refreshFlag)
            }
            Button("cancelButton", role: .cancel) { }
        }
        .alert("unarchiveItemConfirm", isPresented: $showUnarchiveAlert) {
            Button("unarchiveButton", role: .destructive) {
                VM.unarchiveItem(item: $item)
            }
            Button("cancelButton", role: .cancel) { }
        }
        .alert("deleteItemConfirm", isPresented: $showDeleteAlert) {
            Button("deleteButton", role: .destructive) {
                VM.deleteItem(item: $item, refreshFlag: $refreshFlag)
            }
            Button("cancelButton", role: .cancel) { }
        }
        .onChange(of: VM.itemDeleted) {
            if VM.itemDeleted {
                dismiss()
                VM.itemDeleted = false
            }
        }
        .onChange(of: item.locationId) { loadNames() }
        .onAppear { loadNames() }
    }

    private func loadNames() {
        VM.getLocationName(locationId: item.locationId) { name in
            locationName = name
        }
        VM.getOrganizationName(organizationId: item.organizationId) { name in
            organizationName = name
        }
        Task {
            if let userId = item.createdBy {
                createdByName = await userService.resolveUserName(userId: userId)
            }
            if let userId = item.lastEditBy {
                editedByName = await userService.resolveUserName(userId: userId)
            }
        }
    }


    private var imageSection: some View {
        Group {
            if item.attachments.isEmpty {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: maxWidth * 0.5)
                        .foregroundStyle(.gray.opacity(0.5))

                    Text("noImageAvailableLabel")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .frame(height: maxWidth * 0.65)
                .background(Color.gray.opacity(0.1))
            } else {
                ImageViewer(height: maxWidth, width: maxWidth) {
                    ForEach(item.attachments) { attachment in
                        SecureKFImage(urlString: attachment.link)
                            .containerValue(\.activeViewID, attachment.link)
                    }
                } overlay: {
                    OverlayView()
                } updates: { isPresented, id in
                    self.activeID = id?.base as? String
                }
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .shadow(radius: 4)
            }
        }
        .padding(.horizontal, -16)
    }


    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.forText)

            if !item.description.isEmpty {
                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 14) {
                Image(systemName: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("statusLabel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Group {
                        if let status = ItemStatus(rawValue: item.status) {
                            Text(status.displayName)
                        } else {
                            Text(item.status.capitalized)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.forText)
                }

                Spacer()
            }

            if let mainUser = session.mainUser {
                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "VIEW_ARCHIVED_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                    ($0.permissionName == "VIEW_ARCHIVED_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                }) {
                    Divider()

                    HStack(spacing: 14) {
                        Image(systemName: "archivebox")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("archivedLabel")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(LocalizedStringKey(item.archived == "true" ? "yesButton" : "noButton"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(item.archived == "true" ? .red : .green)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(icon: "mappin.and.ellipse", title: "locationLabel")
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            infoRow(icon: "building.2.fill", label: "Organization", value: organizationName)

            Divider().padding(.leading, 52)

            infoRow(icon: "map.fill", label: "Location", value: locationName)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var categoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "tag.fill", title: "categoriesTitle")

            if item.categories.isEmpty {
                Text("noCategoriesAssigned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(item.categories) { category in
                        Text(category.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.fiitPrimary.opacity(0.1), in: Capsule())
                            .foregroundStyle(.fiitPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var attributesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "list.bullet.rectangle.fill", title: "attributesTitle")

            if !item.attributes.isEmpty {
                ForEach(item.attributes) { attribute in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Button {
                            if shownPopoverId == attribute.id {
                                shownPopoverId = nil
                            } else {
                                shownPopoverId = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    shownPopoverId = attribute.id
                                }
                            }
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color.fiitPrimary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: Binding(
                            get: { shownPopoverId == attribute.id },
                            set: { isShowing in if !isShowing { shownPopoverId = nil } }
                        ), attachmentAnchor: .point(.trailing)) {
                            Text(attribute.description)
                                .presentationCompactAdaptation(.popover)
                                .padding()
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                        }

                        Text(attribute.name + ":")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.forText)

                        Text(attribute.value)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                Text("\"\(item.name)\" does not have any attributes assigned.")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var activityCard: some View {
        Group {
            if let createdAt = item.createdAt?.toDate,
               let createdBy = item.createdBy {

                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(icon: "clock.arrow.circlepath", title: "activitySection")
                        .padding(.bottom, 4)

                    let editDate = item.lastEditAt?.toDate
                    let sameUser = item.lastEditBy == createdBy
                    let sameDate = createdAt == editDate

                    let creatorName = createdByName.isEmpty ? createdBy : createdByName
                    let createdDate = createdAt.formatted(date: .abbreviated, time: .shortened)
                    let createdDateStr = createdAt.formatted(date: .abbreviated, time: .shortened)
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle").font(.caption).foregroundStyle(.secondary)
                        (Text("createdByLabel") + Text(" \(creatorName), \(createdDateStr)")).font(.caption).foregroundStyle(.secondary)
                    }

                    if sameUser && sameDate {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle").font(.caption).foregroundStyle(.secondary)
                            Text("lastEditedNoneLabel").font(.caption).foregroundStyle(.secondary)
                        }
                    } else {
                        let editorName = editedByName.isEmpty ? (item.lastEditBy ?? "-") : editedByName
                        let editedDateStr = editDate?.formatted(date: .abbreviated, time: .shortened) ?? "-"
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle").font(.caption).foregroundStyle(.secondary)
                            (Text("editedByLabel") + Text(" \(editorName), \(editedDateStr)")).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }


    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if let mainUser = session.mainUser {
                if item.archived == "true" {
                    if mainUser.permissionsFlatList.contains(where: {
                        $0.permissionName == "EVERYTHING" ||
                        ($0.permissionName == "UNARCHIVE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                        ($0.permissionName == "UNARCHIVE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                    }) {
                        Button(action: { showUnarchiveAlert.toggle() }) {
                            Label("unarchiveButton", systemImage: "arrow.uturn.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(colors: [.orange, .orange.opacity(0.85)], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .foregroundStyle(.white)
                        }
                    }
                } else {
                    if mainUser.permissionsFlatList.contains(where: {
                        $0.permissionName == "EVERYTHING" ||
                        ($0.permissionName == "ARCHIVE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                        ($0.permissionName == "ARCHIVE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                    }) {
                        Button(action: { showArchiveAlert.toggle() }) {
                            Label("archiveButton", systemImage: "archivebox")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(colors: [.orange, .orange.opacity(0.85)], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                                .foregroundStyle(.white)
                        }
                    }
                }

                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "DELETE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                    ($0.permissionName == "DELETE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                }) {
                    Button(action: { showDeleteAlert.toggle() }) {
                        Label("deleteButton", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }


    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.fiitPrimary)
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(label))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline)
                    .foregroundStyle(.forText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func logRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
