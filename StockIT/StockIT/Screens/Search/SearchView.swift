import SwiftUI
import CodeScanner

struct SearchView: View {
    @EnvironmentObject var session: UserSession
    @StateObject var VM = SearchViewModel()
    
    @State private var showArchiveAlert = false
    @State private var showUnarchiveAlert = false
    @State private var showDeleteAlert = false
    @State private var showEditItem = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            contentAndQR()
        }
        .navigationTitle("searchTitle")
        .searchable(text: $VM.filters.searchText)
        .onAppear {
            VM.getData()
        }
        .refreshable {
            VM.getData(forceRefresh: true)
        }
        .onChange(of: VM.filters) {
            VM.getData()
        }
        .onChange(of: VM.shouldRefresh) { 
            if VM.shouldRefresh {
                VM.refreshFilteredItems()
                VM.shouldRefresh = false
            }
        }
        .sheet(item: $VM.activeFilterSheet) { sheetType in
            filterSheet(for: sheetType)
        }
        .sheet(isPresented: $VM.isShowingScanner) {
            NavigationStack {
                CodeScannerView(
                    codeTypes: [.qr, .ean13, .ean8, .code128],
                    completion: VM.handleScan
                )
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("scanQrCodeTitle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("cancelButton") {
                            VM.isShowingScanner = false
                        }
                        .tint(.fiitPrimary)
                    }
                }
            }
        }
        .navigationDestination(isPresented: isItemPresentedBinding) {
            if let item = VM.selectedItem {
                destinationView(for: item)
            }
        }
        .fullScreenCover(isPresented: $showEditItem) {
            editItemScreen()
        }
        .alert("archiveItemConfirm", isPresented: $showArchiveAlert) {
            Button("yesButton", role: .destructive) { archiveAction() }
            Button("cancelButton", role: .cancel) { }
        }
        .alert("unarchiveItemConfirm", isPresented: $showUnarchiveAlert) {
            Button("yesButton", role: .destructive) { unarchiveAction() }
            Button("cancelButton", role: .cancel) { }
        }
        .alert("deleteItemConfirm", isPresented: $showDeleteAlert) {
            Button("deleteButton", role: .destructive) { deleteAction() }
            Button("cancelButton", role: .cancel) { }
        }
    }
    
    
    @ViewBuilder
    private func contentAndQR() -> some View {
        ScrollView {
            LazyVStack {
                topFilterBar()
                if VM.showAdvancedFilters {
                    advancedFiltersSection()
                }
                mainContentArea()
            }
        }
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    VM.isShowingScanner = true
                }) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [Color.fiitPrimary, Color.fiitPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: Color.fiitPrimary.opacity(0.35), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    
    private func archiveAction() {
        if let index = VM.contextMenuItemIndex, VM.items.indices.contains(index) {
            SingleItemViewModel().archiveItem(item: $VM.items[index], refreshFlag: $VM.shouldRefresh)
        }
    }
    
    private func unarchiveAction() {
        if let index = VM.contextMenuItemIndex, VM.items.indices.contains(index) {
            SingleItemViewModel().unarchiveItem(item: $VM.items[index])
        }
    }
    
    private func deleteAction() {
        if let index = VM.contextMenuItemIndex, VM.items.indices.contains(index) {
            SingleItemViewModel().deleteItem(item: $VM.items[index], refreshFlag: $VM.shouldRefresh)
        }
    }
    
    
    private var isItemPresentedBinding: Binding<Bool> {
        Binding(
            get: { VM.selectedItem != nil },
            set: { if !$0 { VM.selectedItem = nil } }
        )
    }
    
    @ViewBuilder
    private func destinationView(for item: Item) -> some View {
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
    
    @ViewBuilder
    private func editItemScreen() -> some View {
        NavigationStack {
            if let index = VM.contextMenuItemIndex, VM.items.indices.contains(index) {
                UpdateItemView(
                    VM: SingleItemViewModel(),
                    item: $VM.items[index],
                    refreshFlag: $VM.shouldRefresh
                )
                .navigationBarBackButtonHidden()
            }
        }
    }
    
    @ViewBuilder
    private func filterSheet(for sheetType: SearchFilterSheetType) -> some View {
        NavigationStack {
            switch sheetType {
            case .organizations: SearchOrganizationsFilterSheetView(VM: VM)
            case .locations: SearchLocationsFilterSheetView(VM: VM)
            case .categories: SearchCategoriesFilterSheetView(VM: VM)
            case .attributes: SearchAttributesFilterSheetView(VM: VM)
            case .statuses: SearchStatusesFilterSheetView(VM: VM)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    
    @ViewBuilder
    private func topFilterBar() -> some View {
        HStack {
            Button {
                withAnimation { VM.showAdvancedFilters.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Label("filtersLabel", systemImage: VM.areFiltersActive ? "slider.horizontal.3" : "line.3.horizontal.decrease")
                        .tint(VM.areFiltersActive ? .fiitPrimary : .forText)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(VM.showAdvancedFilters ? 180 : 0))
                        .foregroundStyle(Color.forText)
                        .animation(.easeInOut(duration: 0.25), value: VM.showAdvancedFilters)
                }
                .padding(.leading, 25)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Picker("layoutLabel", selection: $VM.itemsLayout) {
                Image(systemName: "square.grid.2x2").tag(0)
                Image(systemName: "list.bullet").tag(1)
                Image(systemName: "square").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .padding(.trailing, 20)
        }
    }
    
    @ViewBuilder
    private func advancedFiltersSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                filterChip(title: "Organizations", count: VM.filters.selectedOrganizationIDs.count) { VM.activeFilterSheet = .organizations }
                filterChip(title: "Locations", count: VM.filters.selectedLocationIDs.count) { VM.activeFilterSheet = .locations }
            }
            
            HStack(spacing: 10) {
                filterChip(title: "Categories", count: VM.filters.selectedCategoryIDs.count) { VM.activeFilterSheet = .categories }
                filterChip(title: "Attributes", count: VM.filters.selectedAttributeIDs.count) { VM.activeFilterSheet = .attributes }
                filterChip(title: "Statuses", count: VM.filters.selectedStatuses.count) { VM.activeFilterSheet = .statuses }
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
                        ForEach(ItemSort.allCases, id: \.self) { sort in
                            Label(sort.displayName, systemImage: sort.iconName).tag(sort)
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
    
    @ViewBuilder
    private func mainContentArea() -> some View {
        if VM.isLoading {
            loadingStateView()
        } else if !VM.items.isEmpty {
            populatedStateView()
        } else {
            emptyStateView()
        }
    }
    
    @ViewBuilder
    private func loadingStateView() -> some View {
        if VM.itemsLayout == 0 {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<8, id: \.self) { _ in ItemGridSkeletonCellView() }
            }.padding(10)
        } else if VM.itemsLayout == 1 {
            ForEach(0..<8, id: \.self) { _ in ItemListSkeletonCellView() }
        } else {
            ForEach(0..<3, id: \.self) { _ in ItemCardSkeletonCellView() }
        }
    }
    
    @ViewBuilder
    private func populatedStateView() -> some View {
        if VM.itemsLayout == 1 || VM.itemsLayout == 2 {
            ForEach(VM.items.indices, id: \.self) { index in
                let item = VM.items[index]
                
                Group {
                    if VM.itemsLayout == 1 {
                        SearchListCellView(VM: VM, showOrganizationName: VM.showOrganizationName, showLocationName: VM.showLocationName, item: item)
                    } else {
                        SearchCardCellView(VM: VM, showOrganizationName: VM.showOrganizationName, showLocationName: VM.showLocationName, item: item)
                    }
                }
                .onTapGesture { VM.selectedItem = item }
                .padding(.horizontal, 16)
                .padding(.vertical, 3)
                .onAppear { VM.loadMoreIfNeeded(currentItem: item) }
                .contextMenu { contextMenu(for: item, itemIndex: index) }
            }
            if VM.isLoadingMore { ProgressView().padding() }
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(VM.items.indices, id: \.self) { index in
                    let item = VM.items[index]
                    SearchGridCellView(VM: VM, showOrganizationName: VM.showOrganizationName, showLocationName: VM.showLocationName, item: item)
                        .onTapGesture { VM.selectedItem = item }
                        .onAppear { VM.loadMoreIfNeeded(currentItem: item) }
                        .contextMenu { contextMenu(for: item, itemIndex: index) }
                }
                if VM.isLoadingMore { ProgressView().padding() }
            }.padding(10)
        }
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(.noItems)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .opacity(0.7)

            VStack(spacing: 8) {
                Text(LocalizedStringKey(VM.noItems ? "noResultsLabel" : "noItemsLabel"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.forText)
                Text(LocalizedStringKey(VM.noItems
                     ? "noItemMatchesSearch"
                     : "startBySearchingHint"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
    
    
    @ViewBuilder
    func filterChip(title: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(LocalizedStringKey(title + ":"))
                Text("\(count)").fontWeight(.bold)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.fiitPrimary.opacity(0.1))
            .foregroundStyle(.fiitPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                }) { Label("editButton", systemImage: "square.and.pencil") }
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
                    }) { Label("unarchiveButton", systemImage: "arrow.uturn.up") }
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
                    }) { Label("archiveButton", systemImage: "archivebox") }
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
                }) { Label("deleteButton", systemImage: "trash") }
            }
        }
    }
}
