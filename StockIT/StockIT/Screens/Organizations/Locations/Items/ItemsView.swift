
import SwiftUI

struct ItemsView: View {
    @EnvironmentObject var session: UserSession
    @StateObject var VM: ItemsViewModel
    @State private var showArchiveAlert = false
    @State private var showUnarchiveAlert = false
    @State private var showDeleteAlert = false
    @State private var showEditItem = false

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    VM.showAdvancedFilters.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: VM.areFiltersActive ? "slider.horizontal.3" : "line.3.horizontal.decrease")
                                        .foregroundStyle(VM.areFiltersActive ? Color.fiitPrimary : Color.forText)
                                    Text("filtersLabel")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(VM.areFiltersActive ? Color.fiitPrimary : Color.forText)

                                    Image(systemName: "chevron.down")
                                        .font(.caption2.weight(.semibold))
                                        .rotationEffect(.degrees(VM.showAdvancedFilters ? 180 : 0))
                                        .foregroundStyle(Color.forText.opacity(0.6))
                                        .animation(.easeInOut(duration: 0.25), value: VM.showAdvancedFilters)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Picker("layoutLabel", selection: $VM.itemsLayout) {
                                Image(systemName: "square.grid.2x2").tag(0)
                                Image(systemName: "list.bullet").tag(1)
                                Image(systemName: "square").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 110)
                            .tint(.fiitPrimary)
                        }

                        if VM.showAdvancedFilters {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    VM.filterChip(title: "Categories", count: VM.filters.selectedCategoryIDs.count) {
                                        VM.activeFilterSheet = .categories
                                    }
                                    VM.filterChip(title: "Attributes", count: VM.filters.selectedAttributeIDs.count) {
                                        VM.activeFilterSheet = .attributes
                                    }
                                    VM.filterChip(title: "Statuses", count: VM.filters.selectedStatuses.count) {
                                        VM.activeFilterSheet = .statuses
                                    }
                                }

                                HStack(alignment: .center) {
                                    Button {
                                        VM.filters.showArchived.toggle()
                                    } label: {
                                        HStack {
                                            Text("archivedItemsLabel")
                                            Text(LocalizedStringKey(VM.filters.showArchived ? "showButton" : "hideButton"))
                                                .fontWeight(.bold)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Color.fiitPrimary.opacity(0.1))
                                        .foregroundStyle(.fiitPrimary)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)

                                    Menu {
                                        Picker("orderLabel", selection: $VM.filters.selectedSort) {
                                            ForEach(ItemSort.allCases) { sort in
                                                Label(sort.displayName, systemImage: sort.iconName)
                                                    .tag(sort)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "arrow.up.arrow.down.circle")
                                            Text(VM.filters.selectedSort.displayName)
                                                .fontWeight(.bold)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Color.fiitPrimary.opacity(0.1))
                                        .foregroundStyle(.fiitPrimary)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    if VM.isLoading {
                        if VM.itemsLayout == 0 {
                            LazyVGrid(columns: VM.columns, spacing: 10) {
                                ForEach(0..<8, id: \.self) { _ in
                                    ItemGridSkeletonCellView()
                                }
                            }
                            .padding(.horizontal)
                        } else if VM.itemsLayout == 1 {
                            ForEach(0..<8, id: \.self) { _ in
                                ItemListSkeletonCellView()
                            }
                        } else {
                            ForEach(0..<3, id: \.self) { _ in
                                ItemCardSkeletonCellView()
                            }
                        }
                    } else if !VM.items.isEmpty {
                        if VM.itemsLayout == 1 || VM.itemsLayout == 2 {
                            ForEach(VM.items.indices, id: \.self) { index in
                                let item = VM.items[index]

                                Group {
                                    if VM.itemsLayout == 1 {
                                        ItemsListCellView(VM: VM, location: VM.location, item: item)
                                    } else {
                                        ItemsCardCellView(VM: VM, location: VM.location, item: item)
                                    }
                                }
                                .onTapGesture {
                                    VM.selectedItem = item
                                }
                                .padding(.horizontal)
                                .onAppear {
                                    VM.loadMoreIfNeeded(currentItem: item)
                                }
                                .contextMenu {
                                    contextMenu(for: item, itemIndex: index)
                                }
                            }
                            if VM.isLoadingMore {
                                ProgressView()
                                    .tint(.fiitPrimary)
                                    .padding()
                            }
                        } else {
                            LazyVGrid(columns: VM.columns, spacing: 10) {
                                ForEach(VM.items.indices, id: \.self) { index in
                                    let item = VM.items[index]

                                    ItemsGridCellView(VM: VM, location: VM.location, item: item)
                                        .onTapGesture {
                                            VM.selectedItem = item
                                        }
                                        .onAppear {
                                            VM.loadMoreIfNeeded(currentItem: item)
                                        }
                                        .contextMenu {
                                            contextMenu(for: item, itemIndex: index)
                                        }
                                }
                                if VM.isLoadingMore {
                                    ProgressView()
                                        .tint(.fiitPrimary)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 0) {
                            Image(.noItems)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(.top, 24)
                                .padding(.bottom, 8)

                            Text(LocalizedStringKey(VM.noItems
                                 ? "noMatchingItems"
                                 : "noItemsYetLabel"))
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.forText)
                                .padding(.bottom, 4)

                            Text(LocalizedStringKey(VM.noItems
                                 ? "tryAdjustingFilters"
                                 : "createFirstItemHint"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 24)
                        }
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.top, 40)
                    }
                }
                .searchable(text: $VM.filters.searchText)
            }

            if let mainUser = session.mainUser,
               mainUser.permissionsFlatList.contains(where: { $0.permissionName == "EVERYTHING" }) ||
                mainUser.permissionsFlatList.contains(where: { $0.permissionName == "CREATE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == VM.organization.organizationId }) ||
                mainUser.permissionsFlatList.contains(where: { $0.permissionName == "CREATE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == VM.location.locationId }) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            VM.showCreateItemView = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.fiitPrimary, Color.fiitPrimary.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.fiitPrimary.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                        .fullScreenCover(isPresented: $VM.showCreateItemView) {
                            NavigationStack {
                                if VM.useWizard {
                                    CreateItemWizardView(VM: SingleItemViewModel(selectedOrganizationId: VM.organization.id, selectedLocationId: VM.location.id, itemsVM: VM))
                                } else {
                                    CreateItemView(VM: SingleItemViewModel(selectedOrganizationId: VM.organization.id, selectedLocationId: VM.location.id, itemsVM: VM))
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(VM.location.name)
        .onAppear {
            VM.getItems()
        }
        .refreshable {
            VM.nextPage = 0
            VM.getItems()
        }
        .onChange(of: VM.filters) {
            VM.nextPage = 0
            VM.getItems()
        }
        .onChange(of: VM.shouldRefresh) {
            if VM.shouldRefresh {
                VM.refreshFilteredItems()
                VM.shouldRefresh = false
            }
        }
        .sheet(item: $VM.activeFilterSheet) { sheetType in
            NavigationStack {
                switch sheetType {
                case .categories:
                    CategoriesFilterSheetView(VM: VM)
                case .attributes:
                    AttributesFilterSheetView(VM: VM)
                case .statuses:
                    StatusesFilterSheetView(VM: VM)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: Binding(
            get: { VM.selectedItem != nil },
            set: { if !$0 { VM.selectedItem = nil } }
        )) {
            if let item = VM.selectedItem {
                ItemDetailView(
                    VM: SingleItemViewModel(),
                    item: Binding(
                        get: { item },
                        set: { updated in
                            if let i = VM.items.firstIndex(where: { $0.id == updated.id }) {
                                VM.items[i] = updated
                            }
                            VM.selectedItem = updated
                        }
                    ),
                    activeID: $VM.activeID,
                    refreshFlag: $VM.shouldRefresh
                )
            }
        }
        .fullScreenCover(isPresented: $showEditItem) {
            NavigationStack {
                if let index = VM.contextMenuItemIndex {
                    UpdateItemView(VM: SingleItemViewModel(), item: $VM.items[index], refreshFlag: $VM.shouldRefresh)
                        .navigationBarBackButtonHidden()
                }
            }
        }
        .alert("archiveItemConfirm", isPresented: $showArchiveAlert) {
            Button("yesButton", role: .destructive) {
                if let index = VM.contextMenuItemIndex {
                    SingleItemViewModel().archiveItem(item: $VM.items[index], refreshFlag: $VM.shouldRefresh)
                }
            }
            Button("cancelButton", role: .cancel) { }
        }
        .alert("unarchiveItemConfirm", isPresented: $showUnarchiveAlert) {
            Button("yesButton", role: .destructive) {
                if let index = VM.contextMenuItemIndex {
                    SingleItemViewModel().unarchiveItem(item: $VM.items[index])
                }
            }
            Button("cancelButton", role: .cancel) { }
        }
        .alert("deleteItemConfirm", isPresented: $showDeleteAlert) {
            Button("deleteButton", role: .destructive) {
                if let index = VM.contextMenuItemIndex {
                    SingleItemViewModel().deleteItem(item: $VM.items[index], refreshFlag: $VM.shouldRefresh)
                }
            }
            Button("cancelButton", role: .cancel) { }
        }
    }

    @ViewBuilder
    func contextMenu(for item: Item, itemIndex: Int) -> some View {
        if let mainUser = session.mainUser {
            if mainUser.permissionsFlatList.contains(where: {
                $0.permissionName == "EVERYTHING" ||
                ($0.permissionName == "EDIT_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                ($0.permissionName == "EDIT_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
            }) {
                Button(action: {
                    VM.contextMenuItemIndex = itemIndex
                    showEditItem.toggle()
                }) {
                    Label("editButton", systemImage: "square.and.pencil")
                }
            }

            if item.archived == "true" {
                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "UNARCHIVE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                    ($0.permissionName == "UNARCHIVE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                }) {
                    Button(action: {
                        VM.contextMenuItemIndex = itemIndex
                        showUnarchiveAlert.toggle()
                    }) {
                        Label("unarchiveButton", systemImage: "arrow.uturn.up")
                    }
                }
            } else {
                if mainUser.permissionsFlatList.contains(where: {
                    $0.permissionName == "EVERYTHING" ||
                    ($0.permissionName == "ARCHIVE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                    ($0.permissionName == "ARCHIVE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
                }) {
                    Button(action: {
                        VM.contextMenuItemIndex = itemIndex
                        showArchiveAlert.toggle()
                    }) {
                        Label("archiveButton", systemImage: "archivebox")
                    }
                }
            }

            if mainUser.permissionsFlatList.contains(where: {
                $0.permissionName == "EVERYTHING" ||
                ($0.permissionName == "DELETE_ITEM" && $0.scopeType == "ORGANIZATION" && $0.scopeId == item.organizationId) ||
                ($0.permissionName == "DELETE_ITEM" && $0.scopeType == "LOCATION" && $0.scopeId == item.locationId)
            }) {
                Button(role: .destructive, action: {
                    VM.contextMenuItemIndex = itemIndex
                    showDeleteAlert.toggle()
                }) {
                    Label("deleteButton", systemImage: "trash")
                }
            }
        }
    }
}
