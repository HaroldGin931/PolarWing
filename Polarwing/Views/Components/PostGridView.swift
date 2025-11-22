//
//  PostGridView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct PostGridView: View {
    let posts: [Post]
    let showUsername: Bool
    
    init(posts: [Post], showUsername: Bool = true) {
        self.posts = posts
        self.showUsername = showUsername
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 2),
                GridItem(.flexible(), spacing: 2)
            ], spacing: 2) {
                ForEach(posts) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        PostCardView(post: post, showUsername: showUsername)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
