import Foundation
import Alamofire
import UIKit
import KeychainAccess

struct ErrorResponse: Decodable, Error {
    let code: String
    let message: String
    
    static func custom(_ msg: String) -> ErrorResponse {
        ErrorResponse(code: "" ,message: msg)
    }
}

class NetworkClient {
    static let shared = NetworkClient()
    let storage = SecureStorage()
    
    let session: Session
    
    let baseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("Chýbajúca alebo neplatná API_BASE_URL v Info.plist")
        }
        return url
    }()
    
    let apiPath = "/api/v1"
    var startURL: String {
        return baseURL.absoluteString + apiPath + "/"
    }
    
    private init() {
        let interceptor = AuthInterceptor()
        self.session = Session(interceptor: interceptor)
    }
    
    func getHeaders() -> HTTPHeaders {
        return ["Content-Type": "application/json"]
    }
    
    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        publicEndpoint: Bool = false
    ) async throws -> T {
        let url = path.hasPrefix("http") ? path : startURL + path
        
        let response = await session.request(url, method: method, parameters: parameters, encoding: URLEncoding.default, headers: getHeaders())
            .validate(statusCode: 200...299)
            .serializingData()
            .response
        
        return try handleResponseData(response)
    }
    
    func request<T: Decodable, E: Encodable>(
        path: String,
        method: HTTPMethod = .post,
        body: E,
        publicEndpoint: Bool = false
    ) async throws -> T {
        let url = path.hasPrefix("http") ? path : startURL + path
        
        let response = await session.request(url, method: method, parameters: body, encoder: JSONParameterEncoder.default, headers: getHeaders())
            .validate(statusCode: 200...299)
            .serializingData()
            .response
        
        return try handleResponseData(response)
    }
    
    func requestVoid<E: Encodable>(
        path: String,
        method: HTTPMethod,
        body: E? = nil
    ) async throws {
        let url = path.hasPrefix("http") ? path : startURL + path
        
        let req: DataRequest
        if let body = body {
            req = session.request(url, method: method, parameters: body, encoder: JSONParameterEncoder.default, headers: getHeaders())
        } else {
            req = session.request(url, method: method, headers: getHeaders())
        }
        
        let response = await req.validate(statusCode: 200...299).serializingData().response
        let _: EmptyResponse = try handleResponseData(response)
    }
    
    func requestVoid(
        path: String,
        method: HTTPMethod
    ) async throws {
        let url = path.hasPrefix("http") ? path : startURL + path
        
        let response = await session.request(url, method: method, headers: getHeaders())
            .validate(statusCode: 200...299)
            .serializingData()
            .response
        
        let _: EmptyResponse = try handleResponseData(response)
    }
    
    func uploadImage<T: Decodable>(
        path: String,
        image: UIImage,
        paramName: String = "file",
        extraParams: [String: String] = [:]
    ) async throws -> T {
        let url = startURL + path
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ErrorResponse.custom("Failed to encode image.")
        }
        
        if imageData.count > 25 * 1024 * 1024 {
            throw ErrorResponse.custom("Image exceeds 25MB limit.")
        }
        
        let response = await session.upload(multipartFormData: { multipartFormData in
            for (key, value) in extraParams {
                if let data = value.data(using: .utf8) {
                    multipartFormData.append(data, withName: key)
                }
            }
            multipartFormData.append(imageData, withName: paramName, fileName: "image.jpg", mimeType: "image/jpeg")
            
        }, to: url, method: .post, headers: getHeaders())
        .validate(statusCode: 200...299)
        .serializingData()
        .response
        
        return try handleResponseData(response)
    }
    
    func handleResponseData<T: Decodable>(_ response: AFDataResponse<Data>) throws -> T {
        switch response.result {
        case .success(let data):
            let decoder = JSONDecoder()
            do {
                if T.self == EmptyResponse.self && data.isEmpty {
                    return EmptyResponse() as! T
                }
                return try decoder.decode(T.self, from: data)
            } catch {
                print("decode error: \(error)")
                throw ErrorResponse.custom("Chyba dekódovania dát.")
            }
        case .failure(let afError):
            if let data = response.data, let customError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw customError
            }
            throw ErrorResponse.custom(afError.localizedDescription)
        }
    }
}

struct EmptyResponse: Decodable {}
