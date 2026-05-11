import Foundation

class GoogleSearchService {
    static let shared = GoogleSearchService()

    private static let serpapiPlaceholders: Set<String> = ["YOUR_SERPAPI_KEY_HERE", "SERPAPI_APIKEY"]

    private var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SERPAPI_APIKEY") as? String,
              !key.isEmpty,
              !Self.serpapiPlaceholders.contains(key) else { return nil }
        return key
    }

    func fetchImage(for query: String) async -> String? {
        guard let apiKey = apiKey else { return nil }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://serpapi.com/search.json?engine=google_images_light&q=\(encodedQuery)&google_domain=google.com&api_key=\(apiKey)"

        print("to serpapi: " + urlString)

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let results = json?["images_results"] as? [[String: Any]],
               let firstResult = results.first,
               let thumbnail = firstResult["original"] as? String {
                print("from serpapi: " + thumbnail)
                return thumbnail
            }
        } catch {
            print("serpapi error: \(error)")
        }
        return nil
    }
}
