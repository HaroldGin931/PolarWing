//
//  APIService.swift
//  Polarwing
//
//  Created on 2025-11-24.
//

import Foundation

// MARK: - Error Types
struct APIError: Codable {
    let code: ErrorCode
    let message: String
    let details: String?
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case code, message, details
        case requestId = "request_id"
    }
    
    enum ErrorCode: String, Codable {
        case invalidSignature = "INVALID_SIGNATURE"
        case unauthorized = "UNAUTHORIZED"
        case badRequest = "BAD_REQUEST"
        case internalError = "INTERNAL_ERROR"
        case unknown = "UNKNOWN"
    }
}

// MARK: - Profile Models
struct ProfileUpdateRequest: Codable {
    let avatarUrl: String
    let bio: String
    let nickname: String
    
    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case bio
        case nickname
    }
}

struct ProfileResponse: Codable {
    let address: String
    let avatarUrl: String
    let bio: String
    let createdAt: String
    let nickname: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case address
        case avatarUrl = "avatar_url"
        case bio
        case createdAt = "created_at"
        case nickname
        case updatedAt = "updated_at"
    }
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    private let baseURL = "https://api-polarwing.ngrok.app/api/v1"
    
    private init() {}
    
    // MARK: - Profile API
    func updateProfile(
        nickname: String,
        avatarUrl: String = "TBD",
        bio: String = "TBD",
        suiAddress: String,
        publicKey: String,
        signature: String,
        action: String = "upload",
        timestamp: Int = 1,
        nonce: Int = 2
    ) async throws -> ProfileResponse {
        let url = URL(string: "\(baseURL)/profile/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        request.setValue(publicKey, forHTTPHeaderField: "X-Sui-Public-Key")
        request.setValue(signature, forHTTPHeaderField: "X-Sui-Signature")
        request.setValue(action, forHTTPHeaderField: "X-Sui-Action")
        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Sui-Timestamp")
        request.setValue("\(nonce)", forHTTPHeaderField: "X-Sui-Nonce")
        
        // Body
        let body = ProfileUpdateRequest(
            avatarUrl: avatarUrl,
            bio: bio,
            nickname: nickname
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 发送请求到: \(url.absoluteString)")
        print("📋 请求头:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 请求体: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        print("📋 响应头:")
        httpResponse.allHeaderFields.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        } else {
            print("📦 响应体: (无法解析为字符串, \(data.count) 字节)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let profile = try decoder.decode(ProfileResponse.self, from: data)
            print("✅ 成功解析 ProfileResponse: \(profile)")
            return profile
            
        case 400, 401, 500:
            let decoder = JSONDecoder()
            let apiError = try decoder.decode(APIError.self, from: data)
            print("❌ API 错误: \(apiError)")
            throw NSError(
                domain: "APIService",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: apiError.message,
                    "code": apiError.code.rawValue,
                    "details": apiError.details ?? ""
                ]
            )
            
        default:
            print("⚠️ 未预期的状态码: \(httpResponse.statusCode)")
            throw NSError(
                domain: "APIService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected status code: \(httpResponse.statusCode)"]
            )
        }
    }
    
    // TODO: Add more API endpoints here
}
