import Foundation
import UIKit

enum OfflineTaskAction: String, Codable {
    case create
    case update
}

struct OfflinePhoto: Codable {
    let localFileName: String
    let position: String
}

struct PendingItemTask: Codable {
    let taskId: String
    let action: OfflineTaskAction
    let itemId: String?
    let requestPayload: CreateItemRequest
    let photos: [OfflinePhoto]
}

class OfflineSyncManager {
    static let shared = OfflineSyncManager()
    private let queueKey = "pending_item_tasks"
    private let fileManager = FileManager.default
    
    private init() {}
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var pendingTasks: [PendingItemTask] {
        get {
            guard let data = UserDefaults.standard.data(forKey: queueKey),
                  let queue = try? JSONDecoder().decode([PendingItemTask].self, from: data) else { return [] }
            return queue
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: queueKey)
            }
        }
    }
    
    func enqueueItemTask(action: OfflineTaskAction, itemId: String? = nil, request: CreateItemRequest, uiPhotos: [ItemPhoto]) {
        let taskId = UUID().uuidString
        var offlinePhotos: [OfflinePhoto] = []
        
        for (index, photo) in uiPhotos.enumerated() {
            let fileName = "offline_\(taskId)_img_\(index).jpg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            if let imageData = photo.photo.jpegData(compressionQuality: 0.8) {
                try? imageData.write(to: fileURL)
                offlinePhotos.append(OfflinePhoto(localFileName: fileName, position: photo.position.rawValue))
            }
        }
        
        let newTask = PendingItemTask(
            taskId: taskId,
            action: action,
            itemId: itemId,
            requestPayload: request,
            photos: offlinePhotos
        )
        
        var currentQueue = pendingTasks
        currentQueue.append(newTask)
        pendingTasks = currentQueue
        
        print("offline saved: \(action.rawValue)")
    }
    
    func syncPendingTasks(itemService: ItemService) {
        let queue = pendingTasks
        guard !queue.isEmpty else { return }
        
        print("sync queue: \(queue.count)")
        
        Task {
            for task in queue {
                do {
                    let finalItemId: String
                    
                    if task.action == .create {
                        let createdItem = try await itemService.createItem(item: task.requestPayload)
                        finalItemId = createdItem.itemId
                    } else {
                        guard let existingIdStr = task.itemId, let existingId = Int(existingIdStr) else { throw ErrorResponse.custom("Chýba ID") }
                        let _ = try await itemService.updateItem(itemID: existingId, item: task.requestPayload)
                        finalItemId = existingIdStr
                    }
                    
                    for offlinePhoto in task.photos {
                        let fileURL = documentsDirectory.appendingPathComponent(offlinePhoto.localFileName)
                        
                        if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData), let posEnum = ItemPhotoPosition(rawValue: offlinePhoto.position) {
                            
                            let photoToUpload = ItemPhoto(photo: image, position: posEnum)
                            try await itemService.uploadPhoto(photo: photoToUpload, itemId: finalItemId)
                            
                            try? fileManager.removeItem(at: fileURL)
                        }
                    }
                    
                    print("synced: \(task.taskId)")
                    removeTask(taskId: task.taskId)
                    
                } catch {
                    print("sync failed \(task.taskId): \(error)")
                }
            }
        }
    }
    
    private func removeTask(taskId: String) {
        var currentQueue = pendingTasks
        currentQueue.removeAll { $0.taskId == taskId }
        pendingTasks = currentQueue
    }
}
