//
//  CacheManager.swift
//  Polarwing
//
//  Created on 2025-11-24.
//

import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 1_000_000_000 // 1GB
    
    // 缓存文件路径
    private var postsCache: URL { cacheDirectory.appendingPathComponent("posts.json") }
    private var profilesCache: URL { cacheDirectory.appendingPathComponent("profiles.json") }
    private var imagesCache: URL { cacheDirectory.appendingPathComponent("images") }
    
    private init() {
        // 使用 Documents 目录来存储持久化的缓存数据
        // Documents 目录不会被系统自动清理，适合存储用户数据
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("PolarwingCache")
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imagesCache, withIntermediateDirectories: true)
        
        // 检查并清理超出限制的缓存
        cleanupIfNeeded()
    }
    
    // MARK: - Posts Cache
    
    func savePosts(_ posts: [Post]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(posts)
            try data.write(to: postsCache)
            print("✅ 成功缓存 \(posts.count) 个帖子")
        } catch {
            print("❌ 缓存帖子失败: \(error.localizedDescription)")
        }
    }
    
    func loadPosts() -> [Post]? {
        guard fileManager.fileExists(atPath: postsCache.path) else {
            print("⚠️ 帖子缓存不存在")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: postsCache)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let posts = try decoder.decode([Post].self, from: data)
            print("✅ 成功加载 \(posts.count) 个缓存帖子")
            return posts
        } catch {
            print("❌ 加载帖子缓存失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Profiles Cache
    
    private var profilesDict: [String: ProfileResponse] = [:]
    
    func saveProfile(_ profile: ProfileResponse, for address: String) {
        profilesDict[address] = profile
        saveProfilesToDisk()
    }
    
    func loadProfile(for address: String) -> ProfileResponse? {
        if profilesDict.isEmpty {
            loadProfilesFromDisk()
        }
        return profilesDict[address]
    }
    
    private func saveProfilesToDisk() {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(profilesDict)
            try data.write(to: profilesCache)
            print("✅ 成功缓存 \(profilesDict.count) 个用户资料")
        } catch {
            print("❌ 缓存用户资料失败: \(error.localizedDescription)")
        }
    }
    
    private func loadProfilesFromDisk() {
        guard fileManager.fileExists(atPath: profilesCache.path) else {
            print("⚠️ 用户资料缓存不存在")
            return
        }
        
        do {
            let data = try Data(contentsOf: profilesCache)
            let decoder = JSONDecoder()
            profilesDict = try decoder.decode([String: ProfileResponse].self, from: data)
            print("✅ 成功加载 \(profilesDict.count) 个缓存用户资料")
        } catch {
            print("❌ 加载用户资料缓存失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Image Cache
    
    func saveImage(_ image: UIImage, for url: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = url.sha256() // 使用 URL 的哈希作为文件名
        let fileURL = imagesCache.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ 成功缓存图片: \(filename)")
        } catch {
            print("❌ 缓存图片失败: \(error.localizedDescription)")
        }
    }
    
    func loadImage(for url: String) -> UIImage? {
        let filename = url.sha256()
        let fileURL = imagesCache.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - Cache Management
    
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return totalSize
    }
    
    func clearCache() {
        do {
            // 删除所有缓存文件
            if fileManager.fileExists(atPath: postsCache.path) {
                try fileManager.removeItem(at: postsCache)
            }
            if fileManager.fileExists(atPath: profilesCache.path) {
                try fileManager.removeItem(at: profilesCache)
            }
            
            // 删除所有图片缓存
            if let files = try? fileManager.contentsOfDirectory(at: imagesCache, includingPropertiesForKeys: nil) {
                for file in files {
                    try? fileManager.removeItem(at: file)
                }
            }
            
            profilesDict.removeAll()
            print("✅ 成功清除所有缓存")
        } catch {
            print("❌ 清除缓存失败: \(error.localizedDescription)")
        }
    }
    
    private func cleanupIfNeeded() {
        let currentSize = getCacheSize()
        
        if currentSize > maxCacheSize {
            print("⚠️ 缓存超出限制 (\(currentSize / 1_000_000)MB / \(maxCacheSize / 1_000_000)MB)，开始清理...")
            
            // 删除最旧的图片文件
            if let files = try? fileManager.contentsOfDirectory(at: imagesCache, includingPropertiesForKeys: [.creationDateKey]) {
                let sortedFiles = files.sorted { file1, file2 in
                    let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 < date2
                }
                
                // 删除前 30% 的旧文件
                let filesToDelete = sortedFiles.prefix(sortedFiles.count * 3 / 10)
                for file in filesToDelete {
                    try? fileManager.removeItem(at: file)
                }
            }
            
            print("✅ 缓存清理完成，当前大小: \(getCacheSize() / 1_000_000)MB")
        }
    }
}

// MARK: - String Extension for SHA256
extension String {
    func sha256() -> String {
        // 简单的哈希实现，用于生成文件名
        let data = Data(self.utf8)
        var hash = data.hashValue
        if hash < 0 {
            hash = -hash
        }
        return "\(hash)"
    }
}
