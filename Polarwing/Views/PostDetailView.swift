//
//  PostDetailView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: post.imageUrl)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: post.userAvatar)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.username)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(timeAgoString(from: post.createdAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    Text(post.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(post.content)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 24) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart")
                                .font(.title3)
                            Text("\(post.likes)")
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.right")
                                .font(.title3)
                            Text("\(post.comments)")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "刚刚"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))分钟前"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))小时前"
        } else {
            return "\(Int(seconds / 86400))天前"
        }
    }
}
