//
//  HomeView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct HomeView: View {
    let posts = MockData.posts
    
    var body: some View {
        NavigationView {
            PostGridView(posts: posts, showUsername: true)
                .navigationTitle("Polarwing")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
