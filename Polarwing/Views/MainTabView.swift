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
    @State private var showCreatePost = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Explore (原 Home)
            HomeView()
                .tag(0)
                .tabItem {
                    Image(systemName: "safari")
                    Text("Explore")
                }
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            
            // Camera
            CameraTabView(onDismiss: {
                selectedTab = previousTab
            })
            .tag(1)
            .tabItem {
                Image(systemName: "camera")
                Text("Camera")
            }
            
            // New Post (占位符，实际使用 sheet)
            Color.clear
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
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(Color(red: 172/255, green: 237/255, blue: 228/255))
        .toolbarBackground(.black, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                // 点击 New Post 时显示 sheet
                showCreatePost = true
                // 返回到之前的 tab
                selectedTab = previousTab
            } else if newValue != 1 {
                previousTab = newValue
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
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
