//
//  MainTabView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Explore (原 Home)
            HomeView()
                .tag(0)
                .tabItem {
                    Image(systemName: "safari")
                    Text("Explore")
                }
            
            // Camera
            CameraTabView(onDismiss: {
                selectedTab = previousTab
            })
            .tag(1)
            .tabItem {
                Image(systemName: "camera")
                Text("Camera")
            }
            
            // New Post
            CreatePostView()
                .tag(2)
                .tabItem {
                    Image(systemName: "paperplane")
                    Text("New Post")
                }
            
            // Me
            ProfileView()
                .tag(3)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Me")
                }
        }
        .tint(Color(red: 172/255, green: 237/255, blue: 228/255))
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue != 1 {
                previousTab = newValue
            }
        }
    }
}

// 相机标签页的包装视图
struct CameraTabView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        CameraView(onDismiss: onDismiss)
            .toolbar(.hidden, for: .tabBar)
    }
}
