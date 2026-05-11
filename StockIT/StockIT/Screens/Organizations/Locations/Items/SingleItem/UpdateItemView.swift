import SwiftUI
import PhotosUI

struct UpdateItemView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: SingleItemViewModel
    @Environment(\.dismiss) var dismiss

    @State private var shownPopoverId: Int? = nil
    @State private var firstload: Bool = true

    @Binding var item: Item
    @Binding var refreshFlag: Bool

    var canEdit: Bool {
        let nameChanged: Bool = VM.name != item.name
        let descChanged: Bool = VM.description != item.description
        let statusChanged: Bool = (VM.status?.rawValue ?? "") != item.status
        let locChanged: Bool = VM.selectedLocationId != Int(item.locationId)
        let basicInfoChanged: Bool = nameChanged || descChanged || statusChanged || locChanged

        let currentCatIds = Set(VM.selectedCategories.map { $0.id })
        let originalCatIds = Set(item.categories.map { $0.id })
        let categoriesChanged: Bool = currentCatIds != originalCatIds

        let attributesChanged: Bool = VM.selectedAttributes.contains { attr in
            !item.attributes.contains(where: { $0.id == attr.id && $0.value == attr.value })
        }

        let hasNewPhotos: Bool = VM.uploadedPhotos.contains(where: { $0.fileId == nil })
        let hasDeletedPhotos: Bool = !VM.filesToDelete.isEmpty

        let hasAnyChanges: Bool = basicInfoChanged || categoriesChanged || attributesChanged || hasNewPhotos || hasDeletedPhotos

        return VM.canSubmit && hasAnyChanges
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                photoCard
                organizationCard
                locationCard
                detailsCard
                categoriesCard
                attributesCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: $VM.showCategories) {
            CategoriesView(VM: VM, selectedCategories: VM.selectedCategories)
                .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $VM.showAttributes) {
            AttributesView(VM: VM)
                .navigationBarBackButtonHidden()
        }
        .photosPicker(isPresented: $VM.showPhotoPicker, selection: $VM.selectedPhotoItems, matching: .images)
        .fullScreenCover(isPresented: $VM.showCamera) {
            MultiCaptureCameraView { photos in
                for photo in photos {
                    VM.uploadedPhotos.append(ItemPhoto(photo: photo, position: .random))
                }
                if !VM.uploadedPhotos.isEmpty {
                    VM.currentPhotoIndex = VM.uploadedPhotos.count - 1
                }
            }
        }
        .confirmationDialog("addPhotoButton", isPresented: $VM.showUploadOptions, titleVisibility: .visible) {
            Button("galleryOption") { VM.showPhotoPicker = true }
            Button("cameraOption") { VM.showCamera = true }
            Button("cancelButton", role: .cancel) { }
        }
        .navigationTitle("updateItemTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("cancelButton") { dismiss() }
                    .foregroundStyle(.fiitPrimary)
            }
            ToolbarItem(placement: .topBarTrailing){
                Button("updateButton") {
                    VM.updateItem(item: $item, refreshFlag: $refreshFlag)
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundStyle(canEdit ? .fiitPrimary : .gray)
                .disabled(!canEdit)
            }
        }
        .onChange(of: VM.checkLocationsAndOrganizations) {
            guard VM.checkLocationsAndOrganizations, let user = session.mainUser else { return }
            VM.filterLocationsAndOrganizations(user: user)
            VM.checkLocationsAndOrganizations = false
        }
        .onAppear {
            if firstload {
                VM.loadExistingPhotos(from: item)

                VM.name = item.name
                VM.description = item.description
                VM.status = ItemStatus(rawValue: item.status)
                VM.selectedOrganizationId = Int(item.organizationId)
                VM.selectedLocationId = Int(item.locationId)
                VM.selectedCategories = item.categories
                VM.selectedAttributes = item.attributes.map {
                    SelectedAttribute(attribute: Attribute(
                        attributeId: $0.attributeId, name: $0.name, description: $0.description,
                        createdBy: $0.createdBy, createdAt: $0.createdAt, lastEditBy: $0.lastEditBy, lastEditAt: $0.lastEditAt
                    ), value: $0.value)
                }

                firstload = false
            }
            VM.fetchData()
        }
    }


    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("photosLabel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("*").foregroundStyle(.red).font(.headline)
            }
            .padding(.bottom, 4)

            let side = UIScreen.main.bounds.width - 64

            TabView(selection: $VM.currentPhotoIndex) {
                ForEach(Array(VM.uploadedPhotos.enumerated()), id: \.offset) { index, photo in
                    VStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo.photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: side, height: side)
                                .clipped()
                                .cornerRadius(12)

                            Button {
                                if let idx = VM.uploadedPhotos.firstIndex(where: { $0.id == photo.id }) {
                                    if let fileID = photo.fileId {
                                        VM.filesToDelete.append(fileID)
                                    }
                                    VM.uploadedPhotos.remove(at: idx)
                                    VM.currentPhotoIndex = max(0, min(VM.currentPhotoIndex, VM.uploadedPhotos.count - 1))
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                    .padding(6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            .offset(x: -10, y: 10)
                        }

                    }
                    .tag(index)
                }

                VStack(spacing: 0) {
                    Button {
                        VM.showUploadOptions = true
                    } label: {
                        VStack {
                            Image(systemName: "plus").font(.system(size: 36))
                            Text("addPhotoButton").font(.caption)
                        }
                        .foregroundStyle(Color.fiitPrimary)
                    }
                }
                .tag(VM.uploadedPhotos.count)
            }
            .frame(width: side, height: side + 30)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity)

            HStack {
                Button {
                    withAnimation { VM.currentPhotoIndex -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(VM.currentPhotoIndex > 0 ? Color.fiitPrimary : Color.gray.opacity(0.3))
                }
                .disabled(VM.currentPhotoIndex <= 0)

                Spacer()

                Text("\(min(VM.currentPhotoIndex + 1, VM.uploadedPhotos.count))/\(VM.uploadedPhotos.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation { VM.currentPhotoIndex += 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(VM.currentPhotoIndex < VM.uploadedPhotos.count ? Color.fiitPrimary : Color.gray.opacity(0.3))
                }
                .disabled(VM.currentPhotoIndex >= VM.uploadedPhotos.count)
            }
            .padding(.horizontal, 16)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var organizationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("organizationLabel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("*").foregroundStyle(.red).font(.headline)
            }

            Picker(selection: $VM.selectedOrganizationId) {
                Text("---").tag(nil as Int?)
                ForEach(VM.organizations) { org in
                    Text(org.name).tag(org.id as Int?)
                }
            } label: {
                EmptyView()
            }
            .tint(.forText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("locationLabel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("*").foregroundStyle(.red).font(.headline)
            }

            Picker(selection: $VM.selectedLocationId) {
                Text("---").tag(nil as Int?)
                ForEach(VM.filteredLocations) { location in
                    Text(location.name).tag(location.id as Int?)
                }
            } label: {
                EmptyView()
            }
            .tint(VM.selectedOrganizationId == nil ? .gray : .forText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .labelsHidden()
            .disabled(VM.selectedOrganizationId == nil)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("itemDetailsTitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            styledField(icon: "textformat", label: "Name", placeholder: "Name", text: $VM.name, required: true)
            Divider().padding(.leading, 44)
            styledField(icon: "text.alignleft", label: "Description", placeholder: "Description", text: $VM.description, required: true)
            Divider().padding(.leading, 44)

            HStack(spacing: 14) {
                Image(systemName: "flag")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 2) {
                        Text("statusLabel")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("*").foregroundStyle(.red)
                    }

                    Picker(selection: $VM.status) {
                        Text("---").tag(nil as ItemStatus?)
                        ForEach(ItemStatus.allCases) { status in
                            Text(status.displayName).tag(status as ItemStatus?)
                        }
                    } label: {
                        Text(VM.status?.displayName ?? LocalizedStringKey("selectStatusPlaceholder"))
                            .font(.subheadline)
                            .foregroundStyle(.forText)
                    }
                    .tint(.forText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()
                }
            }
            .padding(.vertical, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var categoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("categoriesTitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("*").foregroundStyle(.red).font(.headline)
                Spacer()
                if !VM.selectedCategories.isEmpty {
                    Button { VM.showCategories = true } label: {
                        Text("editButton")
                            .font(.caption)
                            .foregroundStyle(Color.fiitPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)

            if !VM.selectedCategories.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(VM.selectedCategories.enumerated()), id: \.element.id) { index, category in
                        if index > 0 {
                            Divider().padding(.leading, 44)
                        }

                        HStack(spacing: 14) {
                            Image(systemName: "folder.fill")
                                .font(.subheadline)
                                .foregroundStyle(.fiitPrimary)
                                .frame(width: 20)

                            Text(category.name)
                                .font(.subheadline)
                                .foregroundStyle(.forText)

                            Spacer()

                            Button(role: .destructive) {
                                if let index = VM.selectedCategories.firstIndex(where: { $0.id == category.id }) {
                                    withAnimation { VM.selectedCategories.remove(at: index) }
                                }
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.body)
                                    .foregroundStyle(.red.opacity(0.8))
                                    .frame(width: 36, height: 36)
                                    .background(Color.red.opacity(0.1), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                }
            } else {
                Button { VM.showCategories = true } label: {
                    HStack {
                        Spacer()
                        Label("selectCategoriesTitle", systemImage: "square.grid.2x2")
                            .foregroundStyle(.fiitPrimary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private var attributesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.fiitPrimary)
                Text("attributesTitle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            ForEach(Array(VM.selectedAttributes.enumerated()), id: \.element.id) { index, attribute in
                if index > 0 {
                    Divider().padding(.leading, 44)
                }

                HStack(alignment: .firstTextBaseline, spacing: 14) {
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
                            .font(.subheadline)
                            .foregroundStyle(Color.fiitPrimary)
                            .frame(width: 20)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { shownPopoverId == attribute.id },
                        set: { isShowing in if !isShowing { shownPopoverId = nil } }
                    ), attachmentAnchor: .point(.trailing)) {
                        Text(attribute.attribute.description)
                            .presentationCompactAdaptation(.popover)
                            .padding()
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(attribute.attribute.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 2) {
                            TextField("valueLabel", text: Binding(
                                get: { attribute.value },
                                set: { newValue in
                                    if let idx = VM.selectedAttributes.firstIndex(where: { $0.id == attribute.id }) {
                                        VM.selectedAttributes[idx].value = newValue
                                    }
                                }
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.forText)

                            Text("*").foregroundStyle(.red)
                        }
                    }

                    Spacer()

                    Button(role: .destructive) {
                        withAnimation { VM.selectedAttributes.removeAll(where: { $0.id == attribute.id }) }
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.body)
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.red.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }

            Divider().padding(.leading, 44)

            Button {
                VM.showAttributes = true
            } label: {
                HStack {
                    Spacer()
                    Label("addAttributeButton", systemImage: "plus")
                        .font(.body)
                        .foregroundStyle(.fiitPrimary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }


    private func styledField(icon: String, label: String, placeholder: String, text: Binding<String>, required: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.fiitPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 2) {
                    Text(LocalizedStringKey(label))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if required {
                        Text("*").foregroundStyle(.red)
                    }
                }
                TextField(LocalizedStringKey(placeholder), text: text)
                    .font(.subheadline)
                    .foregroundStyle(.forText)
            }
        }
        .padding(.vertical, 4)
    }
}
