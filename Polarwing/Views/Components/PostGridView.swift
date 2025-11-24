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
        GeometryReader { geometry in
            ScrollView {
                WaterfallLayout(
                    posts: posts,
                    showUsername: showUsername,
                    availableWidth: geometry.size.width - 4
                )
                .padding(.horizontal, 2)
            }
        }
    }
}

// 瀑布流布局
struct WaterfallLayout: View {
    let posts: [Post]
    let showUsername: Bool
    let availableWidth: CGFloat
    let columns = 2
    let spacing: CGFloat = 4
    
    var columnWidth: CGFloat {
        (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(postsForColumn(columnIndex), id: \.id) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            PostCardView(post: post, showUsername: showUsername)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
    }
    
    private func postsForColumn(_ columnIndex: Int) -> [Post] {
        return posts.enumerated().compactMap { index, post in
            index % columns == columnIndex ? post : nil
        }
    }
}
