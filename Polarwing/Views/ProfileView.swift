//
//  ProfileView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var passkeyManager = PasskeyManager.shared
    @State private var tapCount = 0
    @State private var showPasskeyInfo = false
    
    // 模拟当前用户的帖子（实际应该从数据源筛选）
    let currentUserId = "user1"
    
    var username: String {
        UserDefaults.standard.string(forKey: "username") ?? "用户"
    }
    
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
                        .onTapGesture {
                            tapCount += 1
                            if tapCount >= 3 {
                                showPasskeyInfo = true
                                tapCount = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                tapCount = 0
                            }
                        }
                    
                    Text(username)
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
            .sheet(isPresented: $showPasskeyInfo) {
                PasskeyDebugView()
            }
        }
    }
}

struct PasskeyDebugView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passkeyManager = PasskeyManager.shared
    @State private var copied = false
    
    var passkeyID: String {
        passkeyManager.currentCredentialID ?? passkeyManager.getSavedCredentialID()?.base64EncodedString() ?? "未设置"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Passkey ID")
                    .font(.headline)
                
                Text(passkeyID)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .textSelection(.enabled)
                
                Button(action: {
                    UIPasteboard.general.string = passkeyID
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }) {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "已复制" : "复制")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Passkey调试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}
