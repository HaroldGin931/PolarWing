//
//  PostCardView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct PostCardView: View {
    let post: Post
    let showUsername: Bool
    @State private var imageData: UIImage?
    @State private var isLoadingImage = false
    @State private var authorProfile: ProfileResponse?
    @State private var authorAvatarImage: UIImage?
    
    init(post: Post, showUsername: Bool = true) {
        self.post = post
        self.showUsername = showUsername
    }
    
    var displayTitle: String {
        post.title ?? post.contentTitle ?? "无标题"
    }
    
    var displayUsername: String {
        if let profile = authorProfile {
            let nickname = profile.nickname
            if !nickname.isEmpty && nickname != "TBD" {
                return nickname
            }
        }
        return post.username
    }
    
    var hasImage: Bool {
        let mediaUrls = post.mediaUrls ?? post.contentMediaUrls
        if let urlString = mediaUrls?.first,
           (urlString.hasPrefix("http://") || urlString.hasPrefix("https://")) {
            return true
        }
        return false
    }
    
    // 根据内容动态计算高度比例
    var cardAspectRatio: CGFloat {
        if hasImage {
            // 有图片时使用 3:4 比例
            return 0.75
        } else {
            // 纯文本时使用更小的高度，根据标题长度动态调整
            let titleLength = displayTitle.count
            if titleLength < 15 {
                return 1.8  // 很短的标题，最矮的卡片
            } else if titleLength < 30 {
                return 1.4  // 中等长度标题
            } else {
                return 1.0  // 较长标题
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if hasImage {
                    // 有图片时显示图片或加载状态
                    if let image = imageData {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else if isLoadingImage {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                } else {
                    // 纯文本时使用渐变背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 172/255, green: 237/255, blue: 228/255).opacity(0.3),
                            Color(red: 172/255, green: 237/255, blue: 228/255).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(hasImage ? .subheadline : .body)
                        .fontWeight(.semibold)
                        .foregroundColor(hasImage ? .white : .black.opacity(0.85))
                        .lineLimit(hasImage ? 2 : 4)
                        .padding(.bottom, hasImage ? 0 : 4)
                    
                    HStack(spacing: 8) {
                        if showUsername {
                            HStack(spacing: 4) {
                                // 显示用户头像
                                if let avatarImage = authorAvatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16, height: 16)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: post.userAvatar)
                                        .font(.caption2)
                                }
                                Text(displayUsername)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text("\(post.likes)")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(hasImage ? .white.opacity(0.9) : .black.opacity(0.6))
                }
                .padding(hasImage ? 8 : 12)
            }
        }
        .aspectRatio(cardAspectRatio, contentMode: .fit)
        .cornerRadius(8)
        .onAppear {
            if hasImage {
                loadImage()
            }
            loadAuthorProfile()
        }
    }
    
    private func loadImage() {
        // 获取图片 URL（优先使用 mediaUrls，其次使用 contentMediaUrls）
        let mediaUrls = post.mediaUrls ?? post.contentMediaUrls
        guard let urlString = mediaUrls?.first,
              let url = URL(string: urlString) else {
            return
        }
        
        // 跳过系统图标名称
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            // 先尝试从缓存加载
            if let cachedImage = CacheManager.shared.loadImage(for: urlString) {
                self.imageData = cachedImage
                return
            }
            
            isLoadingImage = true
            
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.imageData = image
                            self.isLoadingImage = false
                            // 缓存图片
                            CacheManager.shared.saveImage(image, for: urlString)
                        }
                    } else {
                        await MainActor.run {
                            self.isLoadingImage = false
                        }
                    }
                } catch {
                    print("❌ 加载图片失败 (\(urlString)): \(error.localizedDescription)")
                    await MainActor.run {
                        self.isLoadingImage = false
                    }
                }
            }
        }
    }
    
    private func loadAuthorProfile() {
        // 如果已经有作者信息，跳过
        if authorProfile != nil {
            return
        }
        
        // 先尝试从缓存加载
        if let cachedProfile = CacheManager.shared.loadProfile(for: post.author) {
            self.authorProfile = cachedProfile
            
            // 尝试从缓存加载头像
            let avatarUrl = cachedProfile.avatarUrl
            if avatarUrl != "TBD" && !avatarUrl.isEmpty {
                if let cachedImage = CacheManager.shared.loadImage(for: avatarUrl) {
                    self.authorAvatarImage = cachedImage
                    return // 缓存命中，直接返回
                }
            }
        }
        
        Task {
            do {
                let profile = try await APIService.shared.getProfile(suiAddress: post.author)
                
                await MainActor.run {
                    self.authorProfile = profile
                    // 缓存用户资料
                    CacheManager.shared.saveProfile(profile, for: post.author)
                }
                
                // 加载头像图片
                let avatarUrl = profile.avatarUrl
                if avatarUrl != "TBD" && !avatarUrl.isEmpty,
                   let url = URL(string: avatarUrl) {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.authorAvatarImage = image
                            // 缓存头像图片
                            CacheManager.shared.saveImage(image, for: avatarUrl)
                        }
                    }
                }
            } catch {
                // 静默失败，使用默认显示
                print("⚠️ 获取作者信息失败 (\(post.author)): \(error.localizedDescription)")
            }
        }
    }
}
