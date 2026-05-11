import Foundation
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    private let itemService = ItemService()
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = !(self?.isConnected ?? true)
                self?.isConnected = path.status == .satisfied
                
                if wasOffline && self?.isConnected == true {
                    OfflineSyncManager.shared.syncPendingTasks(itemService: self!.itemService)
                }
            }
        }
        monitor.start(queue: queue)
    }
}
