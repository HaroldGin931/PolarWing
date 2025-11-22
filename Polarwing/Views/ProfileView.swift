//
//  ProfileView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct ProfileView: View {
    // 模拟当前用户的帖子（实际应该从数据源筛选）
    let currentUserId = "user1"
    
    var userPosts: [Post] {
        MockData.posts.filter { $0.userId == currentUserId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 用户信息头部
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Alice")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            Text("\(userPosts.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("帖子")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(userPosts.reduce(0) { $0 + $1.likes })")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("获赞")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 20)
                
                Divider()
                
                // 用户的帖子网格
                if userPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("还没有发布帖子")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PostGridView(posts: userPosts, showUsername: false)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
