//
//  MainTabView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct MainTabView: View {
    @State private var showCreatePost = false
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("")
                }
                .onAppear {
                    showCreatePost = true
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Me")
                }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
}
