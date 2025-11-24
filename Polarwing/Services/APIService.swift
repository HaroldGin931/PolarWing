//
//  APIService.swift
//  Polarwing
//
//  Created on 2025-11-24.
//

import Foundation
import UIKit

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
        case alreadyLiked = "ALREADY_LIKED"
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

// MARK: - Media Upload Models
struct MediaUploadResponse: Codable {
    let files: [UploadedFile]
    let storageType: String
    let totalSize: Int
    
    enum CodingKeys: String, CodingKey {
        case files
        case storageType = "storage_type"
        case totalSize = "total_size"
    }
}

struct UploadedFile: Codable {
    let filename: String
    let size: Int
    let contentType: String
    let url: String
    let blobId: String?
    
    enum CodingKeys: String, CodingKey {
        case filename, size
        case contentType = "content_type"
        case url
        case blobId = "blob_id"
    }
}

// MARK: - Post Models
struct CreatePostRequest: Codable {
    let content: PostContent
    let storageType: String
    let tags: [String]
    let visibility: String
    
    enum CodingKeys: String, CodingKey {
        case content
        case storageType = "storage_type"
        case tags
        case visibility
    }
}

struct PostContent: Codable {
    let ciphertext: String
    let content: String
    let encrypted: Bool
    let mediaUrls: [String]
    let nonce: String
    let sealPolicyId: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case ciphertext, content, encrypted
        case mediaUrls = "media_urls"
        case nonce
        case sealPolicyId = "seal_policy_id"
        case title
    }
}

struct PostResponse: Codable {
    let id: String
    let author: String
    let contentTitle: String?
    let contentText: String?
    let contentMediaUrls: [String]?
    let tags: [String]
    let visibility: String
    let storageType: String
    let blobId: String?
    let sealPolicyId: String?
    let txDigest: String?
    let likeCount: Int
    let commentCount: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, author
        case contentTitle = "content_title"
        case contentText = "content_text"
        case contentMediaUrls = "content_media_urls"
        case tags, visibility
        case storageType = "storage_type"
        case blobId = "blob_id"
        case sealPolicyId = "seal_policy_id"
        case txDigest = "tx_digest"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
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
    
    // MARK: - Media Upload API
    func uploadMedia(
        image: UIImage,
        storageType: String = "walrus",
        suiAddress: String,
        publicKey: String,
        signature: String,
        action: String = "upload",
        timestamp: Int,
        nonce: Int
    ) async throws -> MediaUploadResponse {
        let url = URL(string: "\(baseURL)/media/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        request.setValue(publicKey, forHTTPHeaderField: "X-Sui-Public-Key")
        request.setValue(signature, forHTTPHeaderField: "X-Sui-Signature")
        request.setValue(action, forHTTPHeaderField: "X-Sui-Action")
        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Sui-Timestamp")
        request.setValue("\(nonce)", forHTTPHeaderField: "X-Sui-Nonce")
        
        // 构建 multipart/form-data body
        var body = Data()
        
        // 添加 storage_type 字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"storage_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(storageType)\r\n".data(using: .utf8)!)
        
        // 添加图片文件
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"avatar.jpeg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        print("📤 上传图片到: \(url.absoluteString)")
        print("📋 请求头:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        print("📦 请求体大小: \(body.count) 字节")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let uploadResponse = try decoder.decode(MediaUploadResponse.self, from: data)
            print("✅ 成功上传图片: \(uploadResponse.files.first?.url ?? "无URL")")
            return uploadResponse
            
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
    
    // MARK: - Get Profile API
    func getProfile(
        suiAddress: String
    ) async throws -> ProfileResponse {
        let url = URL(string: "\(baseURL)/profile/\(suiAddress)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        
        print("📤 获取用户信息: \(url.absoluteString)")
        print("📋 请求头:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        } else {
            print("📦 响应体: (无法解析为字符串, \(data.count) 字节)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let profile = try decoder.decode(ProfileResponse.self, from: data)
            print("✅ 成功获取用户信息: \(profile.nickname)")
            return profile
            
        case 400, 401, 404, 500:
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
    
    // MARK: - Post API
    func createPost(
        title: String,
        content: String,
        mediaUrls: [String],
        tags: [String] = [],
        visibility: String = "public",
        storageType: String = "walrus",
        suiAddress: String,
        publicKey: String,
        signature: String,
        action: String = "post",
        timestamp: Int,
        nonce: Int
    ) async throws -> PostResponse {
        let url = URL(string: "\(baseURL)/posts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
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
        let postContent = PostContent(
            ciphertext: "",
            content: content,
            encrypted: false,
            mediaUrls: mediaUrls,
            nonce: "\(nonce)",
            sealPolicyId: "",
            title: title
        )
        
        let body = CreatePostRequest(
            content: postContent,
            storageType: storageType,
            tags: tags,
            visibility: visibility
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 创建帖子: \(url.absoluteString)")
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
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        } else {
            print("📦 响应体: (无法解析为字符串, \(data.count) 字节)")
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let post = try decoder.decode(PostResponse.self, from: data)
            print("✅ 成功创建帖子: \(post.id)")
            return post
            
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
    
    // MARK: - Get Posts API
    func getPosts(
        scope: String = "all",
        page: Int = 1,
        pageSize: Int = 20,
        includeContent: Bool = false,
        suiAddress: String
    ) async throws -> PostsPageResponse {
        var components = URLComponents(string: "\(baseURL)/posts")!
        components.queryItems = [
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "include_content", value: "\(includeContent)")
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        
        print("📤 获取帖子列表: \(url.absoluteString)")
        print("📋 请求头:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        } else {
            print("📦 响应体: (无法解析为字符串, \(data.count) 字节)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let postsPage = try decoder.decode(PostsPageResponse.self, from: data)
            print("✅ 成功获取帖子列表: \(postsPage.posts.count) 个帖子")
            return postsPage
            
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
    
    // MARK: - Get Post Content API
    func getPostContent(
        postId: String,
        suiAddress: String
    ) async throws -> PostContentResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/content")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        
        print("📤 获取帖子内容: \(url.absoluteString)")
        print("📋 请求头:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        } else {
            print("📦 响应体: (无法解析为字符串, \(data.count) 字节)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let postContent = try decoder.decode(PostContentResponse.self, from: data)
            print("✅ 成功获取帖子内容: \(postContent.title)")
            return postContent
            
        case 400, 401, 403, 404, 500:
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
    
    // MARK: - Like API
    func likePost(
        postId: String,
        suiAddress: String,
        publicKey: String,
        signature: String,
        action: String = "like",
        timestamp: Int,
        nonce: Int
    ) async throws -> LikeCountResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        request.setValue(publicKey, forHTTPHeaderField: "X-Sui-Public-Key")
        request.setValue(signature, forHTTPHeaderField: "X-Sui-Signature")
        request.setValue(action, forHTTPHeaderField: "X-Sui-Action")
        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Sui-Timestamp")
        request.setValue("\(nonce)", forHTTPHeaderField: "X-Sui-Nonce")
        
        print("📤 点赞帖子: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let response = try decoder.decode(LikeCountResponse.self, from: data)
            print("✅ 成功点赞，当前点赞数: \(response.likeCount)")
            return response
            
        case 400, 401, 403, 409, 500:
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
    
    // MARK: - Unlike API
    func unlikePost(
        postId: String,
        suiAddress: String,
        publicKey: String,
        signature: String,
        action: String = "unlike",
        timestamp: Int,
        nonce: Int
    ) async throws -> LikeCountResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        request.setValue(publicKey, forHTTPHeaderField: "X-Sui-Public-Key")
        request.setValue(signature, forHTTPHeaderField: "X-Sui-Signature")
        request.setValue(action, forHTTPHeaderField: "X-Sui-Action")
        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Sui-Timestamp")
        request.setValue("\(nonce)", forHTTPHeaderField: "X-Sui-Nonce")
        
        print("📤 取消点赞帖子: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let response = try decoder.decode(LikeCountResponse.self, from: data)
            print("✅ 成功取消点赞，当前点赞数: \(response.likeCount)")
            return response
            
        case 400, 401, 404, 500:
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
    
    // MARK: - Comments API
    func getComments(
        postId: String,
        page: Int = 1,
        pageSize: Int = 20,
        includeContent: Bool = true,
        suiAddress: String
    ) async throws -> CommentsPageResponse {
        var components = URLComponents(string: "\(baseURL)/posts/\(postId)/comments")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "include_content", value: "\(includeContent)")
        ]
        
        guard let url = components.url else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        
        print("📤 获取评论列表: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let commentsPage = try decoder.decode(CommentsPageResponse.self, from: data)
            print("✅ 成功获取评论列表: \(commentsPage.comments.count) 条评论")
            return commentsPage
            
        case 400, 401, 403, 500:
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
    
    func createComment(
        postId: String,
        text: String,
        storageType: String = "walrus",
        suiAddress: String,
        publicKey: String,
        signature: String,
        action: String = "comment",
        timestamp: Int,
        nonce: Int
    ) async throws -> CommentResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
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
        let commentContent = CommentContent(text: text)
        let body = CreateCommentRequest(
            content: commentContent,
            storageType: storageType
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 发表评论: \(url.absoluteString)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 请求体: \(bodyString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 201:
            let decoder = JSONDecoder()
            let comment = try decoder.decode(CommentResponse.self, from: data)
            print("✅ 成功发表评论: \(comment.id)")
            return comment
            
        case 400, 401, 403, 500:
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
    
    func getCommentContent(
        commentId: String,
        suiAddress: String
    ) async throws -> CommentContentResponse {
        let url = URL(string: "\(baseURL)/comments/\(commentId)/content")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Headers
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(suiAddress, forHTTPHeaderField: "X-Sui-Address")
        
        print("📤 获取评论内容: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📦 响应体: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let commentContent = try decoder.decode(CommentContentResponse.self, from: data)
            print("✅ 成功获取评论内容")
            return commentContent
            
        case 400, 401, 403, 500:
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
}

// MARK: - Like Count Response
struct LikeCountResponse: Codable {
    let likeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case likeCount = "like_count"
    }
}

// MARK: - Comment Models
struct CommentResponse: Codable {
    let id: String
    let postId: String
    let author: String
    let blobId: String?
    let contentText: String?
    let storageType: String
    let txDigest: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case author
        case blobId = "blob_id"
        case contentText = "content_text"
        case storageType = "storage_type"
        case txDigest = "tx_digest"
        case createdAt = "created_at"
    }
}

struct CommentContent: Codable {
    let text: String
}

struct CreateCommentRequest: Codable {
    let content: CommentContent
    let storageType: String
    
    enum CodingKeys: String, CodingKey {
        case content
        case storageType = "storage_type"
    }
}

struct CommentsPageResponse: Codable {
    let comments: [CommentResponse]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case comments, total, page
        case pageSize = "page_size"
        case hasMore = "has_more"
    }
}

struct CommentContentResponse: Codable {
    let text: String
}

// MARK: - Posts Page Response
struct PostsPageResponse: Codable {
    let posts: [Post]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case posts, total, page
        case pageSize = "page_size"
        case hasMore = "has_more"
    }
}

// MARK: - Post Content Response
struct PostContentResponse: Codable {
    let title: String
    let content: String
    let mediaUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case title, content
        case mediaUrls = "media_urls"
    }
}
