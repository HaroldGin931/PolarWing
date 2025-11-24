//
//  HomeView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct HomeView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if posts.isEmpty && isLoading {
                    // 只有在首次加载且没有数据时才显示加载状态
                    VStack {
                        ProgressView()
                            .padding()
                        Text("Loading posts...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else if posts.isEmpty && !isLoading && errorMessage != nil {
                    // 只有在没有数据且加载失败时才显示错误
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Loading Failed")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(errorMessage!)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            loadPosts()
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color(red: 172/255, green: 237/255, blue: 228/255))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                } else if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Posts Yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    // 有数据时显示内容,即使正在刷新也保持显示
                    PostGridView(posts: posts, showUsername: true)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Polarwing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadPosts) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(red: 172/255, green: 237/255, blue: 228/255))
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if posts.isEmpty {
                    loadPosts()
                }
            }
        }
    }
    
    private func loadPosts() {
        // 先加载缓存的帖子
        if let cachedPosts = CacheManager.shared.loadPosts() {
            self.posts = cachedPosts
            print("✅ 加载了 \(cachedPosts.count) 个缓存帖子")
        }
        
        // 获取当前用户地址（如果有的话）
        let suiAddress = UserDefaults.standard.string(forKey: "suiAddress") ?? ""
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 获取所有公开可见的帖子
                let postsPage = try await APIService.shared.getPosts(
                    scope: "all",
                    page: 1,
                    pageSize: 50,
                    includeContent: false,
                    suiAddress: suiAddress
                )
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                // 用于存储已完全加载好的帖子（包括内容和图片）
                var loadedPosts: [Post] = []
                
                // 逐个获取帖子的详细内容和图片，下载好一个显示一个
                for var post in postsPage.posts {
                    // 如果帖子是 Walrus 存储，且缺少完整内容（没有标题或没有图片URL），则获取详细内容
                    let needsContent = post.storageType == "walrus" && 
                                      (post.contentTitle == nil || post.contentMediaUrls == nil || post.contentMediaUrls?.isEmpty == true)
                    
                    if needsContent {
                        do {
                            let content = try await APIService.shared.getPostContent(
                                postId: post.id,
                                suiAddress: suiAddress
                            )
                            
                            // 更新帖子内容
                            post.title = content.title
                            post.content = content.content
                            post.mediaUrls = content.mediaUrls
                            
                            print("✅ 获取帖子 \(post.id) 的内容: \(content.title), 图片数: \(content.mediaUrls.count)")
                        } catch {
                            print("⚠️ 获取帖子 \(post.id) 内容失败: \(error.localizedDescription)")
                            // 内容获取失败，跳过这个帖子
                            continue
                        }
                    }
                    
                    // 如果帖子有图片，预下载图片
                    let mediaUrls = post.mediaUrls ?? post.contentMediaUrls
                    if let urlString = mediaUrls?.first,
                       (urlString.hasPrefix("http://") || urlString.hasPrefix("https://")),
                       let imageUrl = URL(string: urlString) {
                        
                        // 检查缓存
                        if CacheManager.shared.loadImage(for: urlString) == nil {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                                if let image = UIImage(data: data) {
                                    // 缓存图片
                                    CacheManager.shared.saveImage(image, for: urlString)
                                    print("✅ 下载帖子 \(post.id) 的图片")
                                }
                            } catch {
                                print("⚠️ 下载帖子 \(post.id) 的图片失败: \(error.localizedDescription)")
                                // 图片下载失败也显示帖子，只是会显示占位符
                            }
                        }
                    }
                    
                    // 将下载好内容和图片的帖子添加到列表并立即显示
                    loadedPosts.append(post)
                    await MainActor.run {
                        self.posts = loadedPosts
                    }
                }
                
                // 全部下载完成后缓存
                await MainActor.run {
                    CacheManager.shared.savePosts(loadedPosts)
                    print("✅ 成功加载并缓存 \(loadedPosts.count) 个帖子")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("❌ 加载帖子失败: \(error.localizedDescription)")
                }
            }
        }
    }
}
