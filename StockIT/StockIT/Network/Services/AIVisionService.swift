import Foundation
import GoogleGenerativeAI
import UIKit

struct AIItemResult: Identifiable {
    let id = UUID()
    var name: String = ""
    var description: String = ""
    var confidence: String = ""
    var categoryNames: [String] = []
}

class AIVisionService: ObservableObject {
    static let shared = AIVisionService()

    private static let keychainKeyAPI = "GeminiAPIKey"
    private static let keychainKeyNote = "GeminiAPIKeyNote"
    private let storage = SecureStorage()

    private var _model: GenerativeModel?
    private var lastAPIKey: String?

    private var model: GenerativeModel? {
        guard let key = resolveAPIKey() else { return nil }
        if _model == nil || key != lastAPIKey {
            lastAPIKey = key
            _model = GenerativeModel(
                name: "gemini-2.5-flash-lite",
                apiKey: key,
                generationConfig: GenerationConfig(temperature: 0.3, topP: 0.8, maxOutputTokens: 256),
                safetySettings: [
                    SafetySetting(harmCategory: .hateSpeech, threshold: .blockNone),
                    SafetySetting(harmCategory: .dangerousContent, threshold: .blockNone),
                    SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockNone),
                    SafetySetting(harmCategory: .harassment, threshold: .blockNone)
                ]
            )
        }
        return _model
    }

    private static let geminiPlaceholders: Set<String> = ["YOUR_GEMINI_API_KEY_HERE", "GEMINI_API_KEY"]

    private func resolveAPIKey() -> String? {
        if let keychainKey = storage.get(Self.keychainKeyAPI), !keychainKey.isEmpty {
            return keychainKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !plistKey.isEmpty,
           !Self.geminiPlaceholders.contains(plistKey) {
            return plistKey
        }
        return nil
    }

    var hasAPIKey: Bool {
        if let k = storage.get(Self.keychainKeyAPI), !k.isEmpty { return true }
        if let k = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !k.isEmpty,
           !Self.geminiPlaceholders.contains(k) { return true }
        return false
    }

    var apiKeyNote: String {
        storage.get(Self.keychainKeyNote) ?? ""
    }

    var isUsingKeychain: Bool {
        if let k = storage.get(Self.keychainKeyAPI), !k.isEmpty { return true }
        return false
    }

    func saveAPIKey(_ key: String, note: String) {
        objectWillChange.send()
        storage.save(key, for: Self.keychainKeyAPI)
        storage.save(note, for: Self.keychainKeyNote)
    }

    func deleteAPIKey() {
        objectWillChange.send()
        storage.delete(Self.keychainKeyAPI)
        storage.delete(Self.keychainKeyNote)
    }

    func validateAPIKey(_ key: String) async throws {
        let testModel = GenerativeModel(name: "gemini-2.5-flash-lite", apiKey: key)
        _ = try await testModel.countTokens("ping")
    }

    func analyzePhoto(_ image: UIImage, availableCategories: [String] = []) async -> [AIItemResult] {
        guard let model = model else { return [] }
        let resized = downsample(image, maxDimension: 1536)

        var categoryInstruction = ""
        if !availableCategories.isEmpty {
            let categoryList = availableCategories.joined(separator: ", ")
            categoryInstruction = """

            CATEGORY MATCHING:
            Available categories: [\(categoryList)]
            For each suggestion, pick all fitting categories from the list above.
            If no category fits, return NONE.
            Add matched categories as a 4th field separated by |.
            Format: Exact Product Name | Short Description | Match % | Category1, Category2
            If no categories match: Exact Product Name | Short Description | Match % | NONE
            """
        }

        let prompt = """
        You are an inventory system for historical technology. Analyze the object in the photo and provide exactly 3 most likely possibilities of what it is.

        CRITICAL: Your entire output MUST be in the Slovak language.

        Provide exactly 3 lines of output. Do not include any greetings, explanations, or extra text.
        Each line must strictly follow this format:
        Exact Product Name | Short Museum Description | Match %\(availableCategories.isEmpty ? "" : " | Categories")

        Rules for the "Short Museum Description":
        1. It must be strictly 10 words or fewer.
        2. Each description MUST be completely independent and self-contained. NEVER reference the other options.
        3. All 3 suggestions MUST be different products. NEVER repeat the same item.
        \(categoryInstruction)
        """

        do {
            let response = try await model.generateContent(prompt, resized)
            guard let text = response.text else { return [] }

            return text
                .components(separatedBy: CharacterSet.newlines)
                .filter { !$0.isEmpty }
                .compactMap { line -> AIItemResult? in
                    let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                    guard parts.count >= 3 else { return nil }

                    var categories: [String] = []
                    if parts.count >= 4 {
                        let raw = parts[3].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        if raw.uppercased() != "NONE" && !raw.isEmpty {
                            categories = raw.components(separatedBy: ",").map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                        }
                    }

                    return AIItemResult(
                        name: parts[0],
                        description: parts[1],
                        confidence: parts[2],
                        categoryNames: categories
                    )
                }
        } catch {
            print("ai error: \(error.localizedDescription)")
            return []
        }
    }

    private func downsample(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        if scale >= 1.0 { return image }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
