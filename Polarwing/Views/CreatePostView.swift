//
//  CreatePostView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI
import PhotosUI
import Photos

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var showCamera = false
    @State private var showPhotoGallery = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    // 显示选中的图片
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    // 图片说明输入框
                    TextField("添加图片说明...", text: $caption, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .lineLimit(3...6)
                    
                    Spacer()
                } else {
                    // 选择图片的选项
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Button(action: {
                            showCamera = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                Text("拍照")
                                    .font(.headline)
                            }
                            .foregroundColor(Color(red: 172/255, green: 237/255, blue: 228/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(red: 172/255, green: 237/255, blue: 228/255).opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        Button(action: {
                            showPhotoGallery = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 50))
                                Text("从相册选择")
                                    .font(.headline)
                            }
                            .foregroundColor(Color(red: 172/255, green: 237/255, blue: 228/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color(red: 172/255, green: 237/255, blue: 228/255).opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                }
            }
            .padding()
            .navigationTitle("发帖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                if selectedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("发布") {
                            // TODO: 发布帖子
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView()
            }
            .fullScreenCover(isPresented: $showPhotoGallery) {
                PhotoGalleryPickerView { image in
                    selectedImage = image
                    showPhotoGallery = false
                }
            }
        }
    }
}

// MARK: - 照片选择器（仅显示 Polarwing 相册）
struct PhotoGalleryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PhotoGalleryViewModel()
    let onSelect: (UIImage) -> Void
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.photoAssets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("没有照片")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("请先使用相机拍摄照片")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.photoAssets, id: \.localIdentifier) { asset in
                                GeometryReader { geometry in
                                    PickerThumbnailView(asset: asset) { image in
                                        onSelect(image)
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipped()
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .navigationTitle("选择照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(red: 172/255, green: 237/255, blue: 228/255))
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadPhotos()
        }
    }
}

// MARK: - 选择器缩略图
struct PickerThumbnailView: View {
    let asset: PHAsset
    let onSelect: (UIImage) -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: {
            loadFullImage()
        }) {
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            ProgressView()
                                .tint(Color(red: 172/255, green: 237/255, blue: 228/255))
                        )
                }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        
        let targetSize = CGSize(width: 200, height: 200)
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            self.thumbnail = image
        }
    }
    
    private func loadFullImage() {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let screenScale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds.size
        let targetSize = CGSize(
            width: screenSize.width * screenScale,
            height: screenSize.height * screenScale
        )
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            if let image = image {
                onSelect(image)
            }
        }
    }
}
