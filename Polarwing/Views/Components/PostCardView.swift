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
    
    init(post: Post, showUsername: Bool = true) {
        self.post = post
        self.showUsername = showUsername
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: post.imageUrl)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray.opacity(0.3))
                    )
                
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if showUsername {
                            HStack(spacing: 4) {
                                Image(systemName: post.userAvatar)
                                    .font(.caption2)
                                Text(post.username)
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
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(8)
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
        .cornerRadius(8)
    }
}
