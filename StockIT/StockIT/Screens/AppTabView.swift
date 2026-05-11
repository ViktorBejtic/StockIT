
import SwiftUI

struct AppTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
                    .navigationTitle("dashboardTitle")
            }
            .tabItem {
                Image(systemName: "house")
                    .environment(\.symbolVariants, .none)
                Text("dashboardTitle")
            }
            
            NavigationStack {
                OrganizationsView()
                    .navigationTitle("organizationsTitle")
            }
            .tabItem {
                Image(systemName: "building.2")
                    .environment(\.symbolVariants, .none)
                Text("organizationsTitle")
            }
            
            NavigationStack {
                SearchView()
                    .navigationTitle("searchTitle")
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                    .environment(\.symbolVariants, .none)
                Text("searchTitle")
            }
            
            NavigationStack {
                AccountView()
                    .navigationTitle("accountTitle")
            }
            .tabItem {
                Image(systemName: "person")
                    .environment(\.symbolVariants, .none)
                Text("accountTitle")
            }
        }
        .accentColor(.fiitPrimary)
    }
}
