import SwiftUI
import MapKit
import Charts
import SkeletonUI

struct DashboardView: View {
    @StateObject private var VM = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                organizationPicker

                if !VM.isLoadingItems && VM.items.isEmpty {
                    emptyState
                } else {
                    chartCard

                    recentItemsSection

                    mapCard
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("dashboardTitle")
        .onAppear {
            VM.getOrganizations()
        }
        .onChange(of: VM.selectedOrganizationID) {
            VM.getData(organizationId: VM.selectedOrganizationID)
        }
        .onChange(of: VM.shouldRefresh) {
            if VM.shouldRefresh {
                VM.refreshFilteredItems()
                VM.shouldRefresh = false
            }
        }
        .refreshable {
            VM.getOrganizations(forceRefresh: true)
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
    }


    private var organizationPicker: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.fiitPrimary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "building.2.fill")
                    .foregroundStyle(.fiitPrimary)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("organizationLabel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $VM.selectedOrganizationID) {
                    ForEach(VM.organizations) { org in
                        Text(org.name).tag(org.organizationId)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .labelsHidden()
                .offset(x: -12)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }


    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(.noItems)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .opacity(0.7)

            VStack(spacing: 8) {
                Text("noItemsYetLabel")
                    .font(.title2.weight(.bold))
                Text("This organization doesn't have any items.\nStart by adding your first one!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }


    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("itemsByLocationSection")
                        .font(.headline)
                    Text("\(VM.totalItems) total items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Chart(VM.locations, id: \.id) { item in
                SectorMark(
                    angle: .value("Items", Double(item.itemCount) ?? 0),
                    innerRadius: .ratio(0.63),
                    angularInset: 2
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Location", item.name))
                .opacity(item.id == VM.selectedLocationId ? 1 : 0.5)
            }
            .chartAngleSelection(value: $VM.selectedLocationId)
            .skeleton(
                with: VM.isLoadingLocations,
                animation: .linear(),
                appearance: .solid(color: .gray.opacity(0.3), background: .clear),
                shape: .circle
            )
            .scaledToFill()
            .chartLegend(alignment: .center, spacing: 16)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        VStack(spacing: 4) {
                            if let selected = VM.locations.first(where: { $0.id == VM.selectedLocationId }) {
                                Text(selected.name)
                                    .font(.headline)
                                Text("\(selected.itemCount) item(s)")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            } else {
                                Image(systemName: "shippingbox.fill")
                                    .font(.title2)
                                    .foregroundStyle(.fiitPrimary.opacity(0.6))
                                Text("\(VM.totalItems)")
                                    .font(.title2.bold())
                            }
                        }
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }


    private var recentItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("recentlyAddedSection")
                    .font(.headline)
                Spacer()
                Text("\(VM.metadata.totalElements) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            if VM.isLoadingItems {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(0..<4, id: \.self) { _ in
                            DashboardItemSkeletonCellView()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else if !VM.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(VM.items.indices, id: \.self) { index in
                            let item = VM.items[index]
                            DashboardItemCellView(VM: VM, item: item)
                                .onAppear {
                                    VM.loadMoreIfNeeded(currentItem: item)
                                }
                                .onTapGesture {
                                    VM.selectedItem = item
                                }
                        }
                        if VM.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 230)
            }
        }
    }


    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.fiitPrimary)
                Text("locationLabel")
                    .font(.headline)
                Spacer()
                if let org = VM.selectedOrganization {
                    Text("\(org.city), \(org.country)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Map(position: $VM.mapPosition) {
                if let coord = VM.selectedCoordinate {
                    Marker(VM.selectedOrganization?.name ?? "organizationLabel", coordinate: coord)
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapUserLocationButton()
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
}
