import SwiftUI
import PhotosUI
import AlertToast

struct CreateItemWizardView: View {
    @EnvironmentObject var session: UserSession
    @ObservedObject var VM: SingleItemViewModel
    @Environment(\.dismiss) var dismiss
    @State private var step: Int = 0
    @State private var shownPopoverId: Int? = nil
    @State private var createdItemActiveID: String?
    @State private var createdItemRefreshFlag: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step), total: 4)
                .tint(Color.fiitPrimary)
                .padding()
                .background(Color(.systemGroupedBackground))

            Text(LocalizedStringKey(stepInstruction(for: step)))
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 15)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .background(Color(.systemGroupedBackground))

            contentForCurrentStep

            navigationButtons
        }
        .disabled(VM.isCreating)
        .onAppear {
            VM.isWizardMode = true
            VM.dismissAction = dismiss.callAsFunction
            VM.fetchData()
        }
        .refreshable {
            VM.fetchData(forceRefresh: true)
        }
        .onChange(of: VM.checkLocationsAndOrganizations) {
            guard VM.checkLocationsAndOrganizations, let user = session.mainUser else { return }
            VM.filterLocationsAndOrganizations(user: user)
            VM.checkLocationsAndOrganizations = false
        }
        .onChange(of: VM.isIdentifying) {
            if !VM.isIdentifying && !VM.suggestions.isEmpty && step == 2 {
                VM.showSuggestions = true
            }
        }
        .toast(isPresenting: $VM.showToast, duration: 3, offsetY: 60) {
            AlertToast(
                displayMode: .hud,
                type: .regular,
                subTitle: VM.toastMessage.localized
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("cancelButton") { dismiss() }
                    .foregroundStyle(.fiitPrimary)
                    .disabled(VM.isCreating)
            }
            ToolbarItem(placement: .topBarTrailing){
                if VM.isCreating {
                    ProgressView()
                        .tint(.fiitPrimary)
                } else {
                    Button("createButton") {
                        VM.createItem()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(VM.canSubmit ? .fiitPrimary : .gray)
                    .disabled(!VM.canSubmit)
                }
            }
        }
        .navigationTitle("createItemTitle")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("addPhotoButton", isPresented: $VM.showUploadOptions, titleVisibility: .visible) {
            Button("galleryOption") { VM.showPhotoPicker = true }
            Button("cameraOption") { VM.showCamera = true }
            Button("cancelButton", role: .cancel) { }
        }
        .photosPicker(isPresented: $VM.showPhotoPicker, selection: $VM.selectedPhotoItems, matching: .images)
        .fullScreenCover(isPresented: $VM.showCamera) {
            MultiCaptureCameraView { photos in
                let isFirst = VM.uploadedPhotos.isEmpty
                for photo in photos {
                    VM.uploadedPhotos.append(ItemPhoto(photo: photo, position: .random))
                }
                if !VM.uploadedPhotos.isEmpty {
                    VM.currentPhotoIndex = VM.uploadedPhotos.count - 1
                }
                if isFirst, let first = photos.first, VM.useAI {
                    VM.identifyItem(image: first)
                }
            }
        }
        .sheet(isPresented: $VM.showSuggestions){
            NavigationStack {
                ItemSuggestionsView(VM: VM)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .navigationDestination(isPresented: $VM.showCategories) {
            CategoriesView(VM: VM, selectedCategories: VM.selectedCategories)
                .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: $VM.showAttributes) {
            AttributesView(VM: VM)
                .navigationBarBackButtonHidden()
        }
        .navigationDestination(isPresented: Binding(
            get: { VM.createdItem != nil },
            set: { if !$0 { VM.createdItem = nil } }
        )) {
            if let createdItem = VM.createdItem {
                ItemDetailView(
                    VM: VM,
                    item: Binding(
                        get: { VM.createdItem ?? createdItem },
                        set: { VM.createdItem = $0 }
                    ),
                    activeID: $createdItemActiveID,
                    refreshFlag: $createdItemRefreshFlag
                )
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("closeButton") {
                            VM.dismissAction?()
                        }
                        .foregroundStyle(.fiitPrimary)
                    }
                }
            }
        }
    }


    @ViewBuilder
    private var contentForCurrentStep: some View {
        Group {
            switch step {
            case 0: stepPhotoSelection
            case 1: stepOrganization
            case 2: stepItemDetails
            case 3: stepCategories
            case 4: stepAttributes
            default: EmptyView()
            }
        }
    }


    private var stepPhotoSelection: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("photosLabel")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("*").foregroundStyle(.red).font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                    let side = geo.size.width - 64

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
                            .frame(minHeight: side)
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
                .padding(.horizontal, 16)
                .offset(y: -30)
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
    }


    private var stepOrganization: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("organizationLabel")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("*").foregroundStyle(.red).font(.headline)
                    }
                    .padding(.bottom, 4)

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

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("locationLabel")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("*").foregroundStyle(.red).font(.headline)
                    }
                    .padding(.bottom, 4)

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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
    }


    private var stepItemDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.subheadline)
                            .foregroundStyle(.fiitPrimary)
                        Text("itemDetailsTitle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if VM.useAI && !VM.uploadedPhotos.isEmpty {
                            Button {
                                if !VM.isIdentifying { VM.showSuggestions = true }
                            } label: {
                                HStack(spacing: 5) {
                                    if VM.isIdentifying {
                                        ProgressView()
                                            .controlSize(.mini)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.caption2)
                                    }
                                    Text(VM.isIdentifying ? LocalizedStringKey("analyzingLabel") : LocalizedStringKey("aiSuggestionsLabel"))
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(VM.isIdentifying ? Color.orange : Color.fiitPrimary, in: Capsule())
                            }
                            .disabled(VM.isIdentifying)
                        }
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
    }


    private var stepCategories: some View {
        ScrollView {
            VStack(spacing: 16) {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
    }


    private var stepAttributes: some View {
        ScrollView {
            VStack(spacing: 16) {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
    }


    private var navigationButtons: some View {
        HStack {
            if step > 0 {
                Button {
                    step -= 1
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                        Text("backButton")
                    }
                    .foregroundStyle(Color.fiitPrimary)
                }
            }
            Spacer()
            if step < 4 {
                Button {
                    let nextStep = step + 1
                    step = nextStep
                    if nextStep == 1 && VM.isIdentifying {
                        VM.toastMessage = "aiIdentifyingItem"
                        VM.isSuccess = true
                        VM.showToast = true
                    }
                    if nextStep == 2 && !VM.suggestions.isEmpty && !VM.isIdentifying {
                        VM.showSuggestions = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("nextButton")
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(VM.canProceed(to: step) ? Color.fiitPrimary : .gray)
                }
                .disabled(!VM.canProceed(to: step))
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }


    private func stepInstruction(for step: Int) -> String {
        switch step {
        case 0: return "Please take or upload at least one photo and select the angle for each."
        case 1: return "Choose the organization and corresponding location for this item."
        case 2: return "Fill in the item's name, description and status."
        case 3: return "Select one or more categories that best describe this item."
        case 4: return "Optionally add item attributes with values (e.g., color, RAM, etc.)."
        default: return ""
        }
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
