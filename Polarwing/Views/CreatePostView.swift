//
//  CreatePostView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("发帖功能")
                    .font(.title)
                    .foregroundColor(.gray)
                
                Text("即将推出相机拍摄功能")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
            .navigationTitle("发帖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
