import SwiftUI
import Kingfisher

@main
struct StockITApp: App {
    @StateObject var session = UserSession.shared
    @AppStorage("theme") private var theme: AppTheme = .system
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system

    init() {
        configureKingfisher()
        _ = NetworkMonitor.shared

        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        if lang != "system" {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(theme == .system ? nil :
                                        theme == .light ? .light : .dark)
                .environment(\.locale, appLanguage == .system
                             ? .current
                             : Locale(identifier: appLanguage.rawValue))
                .onChange(of: appLanguage) {
                    if appLanguage == .system {
                        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                    } else {
                        UserDefaults.standard.set([appLanguage.rawValue], forKey: "AppleLanguages")
                    }
                }
        }
    }

    private func configureKingfisher() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(14)
        cache.cleanExpiredDiskCache()
    }
}

struct RootView: View {
    @EnvironmentObject var session: UserSession

    var body: some View {
        Group {
            if session.mainUser == nil && session.isRestoring {
                LaunchAnimationView()
            } else if session.mainUser != nil {
                AppTabView()
            } else {
                LoginView()
            }
        }
        .onAppear{
            session.restoreSession()
        }
        .alert("errorAlertTitle", isPresented: $session.showAlert) {
            Button("okButton", role: .cancel) { }
        } message: {
            Text(session.alertMessage.isEmpty ? String(localized: "genericErrorMessage") : session.alertMessage)
        }
    }
}
