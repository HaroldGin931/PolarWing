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
                        Text("加载帖子中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else if posts.isEmpty && !isLoading && errorMessage != nil {
                    // 只有在没有数据且加载失败时才显示错误
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("加载失败")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(errorMessage!)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("重试") {
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
                        Text("暂无帖子")
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
                
                // 获取每个帖子的详细内容
                var allPosts = postsPage.posts
                
                for i in 0..<allPosts.count {
                    // 如果帖子是 Walrus 存储且没有 contentTitle，则获取详细内容
                    if allPosts[i].storageType == "walrus" && allPosts[i].contentTitle == nil {
                        do {
                            let content = try await APIService.shared.getPostContent(
                                postId: allPosts[i].id,
                                suiAddress: suiAddress
                            )
                            
                            // 更新帖子内容
                            allPosts[i].title = content.title
                            allPosts[i].content = content.content
                            allPosts[i].mediaUrls = content.mediaUrls
                            
                            print("✅ 获取帖子 \(allPosts[i].id) 的内容: \(content.title)")
                        } catch {
                            print("⚠️ 获取帖子 \(allPosts[i].id) 内容失败: \(error.localizedDescription)")
                            // 继续处理其他帖子
                        }
                    }
                }
                
                await MainActor.run {
                    self.posts = allPosts
                    self.isLoading = false
                    
                    // 缓存新获取的帖子
                    CacheManager.shared.savePosts(allPosts)
                    print("✅ 成功加载并缓存 \(allPosts.count) 个帖子")
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
