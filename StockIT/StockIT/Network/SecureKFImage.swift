import Foundation
import SwiftUI
import Kingfisher

struct SecureKFImage: View {
    let urlString: String
    
    var modifier: AnyModifier {
        let token = SecureStorage().get("AccessToken") ?? ""
        return AnyModifier { request in
            var r = request
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return r
        }
    }
    
    var safeURL: URL? {
        let fullURLString = NetworkClient.shared.baseURL.absoluteString + urlString
        
        let encodedString = fullURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fullURLString
        
        return URL(string: encodedString)
    }
    
    var body: some View {
        if let url = safeURL {
            KFImage(url)
                .requestModifier(modifier)
                .placeholder {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .overlay { ProgressView().tint(.fiitPrimary) }
                }
                .retry(maxCount: 3, interval: .seconds(5))
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.1)
                .overlay { Image(systemName: "photo.badge.exclamationmark").foregroundStyle(.gray) }
        }
    }
}
