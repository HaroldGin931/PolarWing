//
//  ProfileView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var p256Signer = P256Signer.shared
    @State private var tapCount = 0
    @State private var showDebugView = false
    
    // 模拟当前用户的帖子（实际应该从数据源筛选）
    let currentUserId = "user1"
    
    var username: String {
        UserDefaults.standard.string(forKey: "username") ?? "用户"
    }
    
    var userPosts: [Post] {
        MockData.posts.filter { $0.userId == currentUserId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 用户信息头部
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            tapCount += 1
                            if tapCount >= 3 {
                                showDebugView = true
                                tapCount = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                tapCount = 0
                            }
                        }
                    
                    Text(username)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            Text("\(userPosts.count)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("帖子")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(userPosts.reduce(0) { $0 + $1.likes })")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("获赞")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 20)
                
                Divider()
                
                // 用户的帖子网格
                if userPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("还没有发布帖子")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PostGridView(posts: userPosts, showUsername: false)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDebugView) {
                P256SignerDebugView()
            }
        }
    }
}

struct P256SignerDebugView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var p256Signer = P256Signer.shared
    @State private var copiedItem = ""
    @State private var publicKey = "未设置"
    @State private var publicKeyHex = "未设置"
    @State private var suiAddress = "未生成"
    @State private var testMessage = "Hello P256 Signature!"
    @State private var lastSignature = "未生成"
    @State private var verificationResult = ""
    @State private var isSigning = false
    @State private var signatureResult: SignatureResult?
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var importPrivateKey = ""
    @State private var exportedPrivateKey = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 说明文字
                    VStack(alignment: .leading, spacing: 8) {
                        Text("P256 密钥管理")
                            .font(.headline)
                        
                        Text("私钥安全存储在 Keychain 中，可导出备份")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Public Key (Base64)
                    DebugInfoSection(
                        title: "P256 公钥 (Base64)",
                        content: publicKey,
                        copiedItem: $copiedItem
                    )
                    
                    // Public Key (Hex)
                    DebugInfoSection(
                        title: "P256 公钥 (Hex)",
                        content: publicKeyHex,
                        copiedItem: $copiedItem
                    )
                    
                    // Sui Address
                    DebugInfoSection(
                        title: "Sui 地址",
                        content: suiAddress,
                        copiedItem: $copiedItem
                    )
                    
                    Divider()
                        .padding(.vertical)
                    
                    // 签名测试部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("签名测试")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("测试消息")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("输入要签名的消息", text: $testMessage)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: signTestMessage) {
                            HStack {
                                if isSigning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "signature")
                                    Text("生成签名")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isSigning || testMessage.isEmpty)
                        
                        if lastSignature != "未生成" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("签名结果 (Base64)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(lastSignature)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .textSelection(.enabled)
                            }
                        }
                        
                        if !verificationResult.isEmpty {
                            HStack {
                                Image(systemName: verificationResult.contains("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(verificationResult.contains("✅") ? .green : .red)
                                Text(verificationResult)
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(verificationResult.contains("✅") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // 显示区块链验证示例
                        if let result = signatureResult, let pk = p256Signer.publicKey {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("区块链验证示例")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(result.toBlockchainVerificationExample(publicKey: pk))
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // 密钥管理部分
                    VStack(spacing: 12) {
                        Text("密钥管理")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 导出私钥
                        Button(action: { showExportSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("导出私钥")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // 导入私钥
                        Button(action: { showImportSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("导入私钥")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // 重新生成密钥对
                        Button(action: regenerateKeyPair) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("重新生成密钥对")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("P256 签名器调试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPublicKey()
            }
            .sheet(isPresented: $showExportSheet) {
                ExportPrivateKeyView(privateKey: exportedPrivateKey)
            }
            .sheet(isPresented: $showImportSheet) {
                ImportPrivateKeyView(importText: $importPrivateKey, onImport: importPrivateKeyAction)
            }
        }
    }
    
    private func loadPublicKey() {
        if let pk = p256Signer.publicKey ?? p256Signer.getSavedPublicKey() {
            publicKey = pk.base64EncodedString()
            publicKeyHex = pk.map { String(format: "%02x", $0) }.joined()
        }
        
        // 生成 Sui 地址
        if let address = p256Signer.generateSuiAddress() {
            suiAddress = address
        }
        
        print("📱 P256 Signer 调试信息:")
        print("  - 公钥 (Base64): \(publicKey)")
        print("  - 公钥 (Hex): \(publicKeyHex)")
        print("  - Sui 地址: \(suiAddress)")
    }
    
    private func regenerateKeyPair() {
        p256Signer.generateKeyPair { result in
            switch result {
            case .success:
                print("✅ 密钥对重新生成成功")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    loadPublicKey()
                }
            case .failure(let error):
                print("❌ 密钥生成失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func signTestMessage() {
        isSigning = true
        verificationResult = ""
        
        p256Signer.signMessage(testMessage) { result in
            isSigning = false
            
            switch result {
            case .success(let result):
                lastSignature = result.signature.base64EncodedString()
                signatureResult = result
                
                print("✅ 签名成功")
                print("  - 消息: \(testMessage)")
                print("  - 签名: \(lastSignature)")
                
                // 立即验证签名
                if let publicKeyData = p256Signer.publicKey ?? p256Signer.getSavedPublicKey() {
                    let isValid = p256Signer.verifySignature(
                        signature: result.signature,
                        message: result.message,
                        publicKey: publicKeyData
                    )
                    
                    verificationResult = isValid ? "✅ 签名验证成功！可用于区块链验证" : "❌ 签名验证失败"
                } else {
                    verificationResult = "❌ 无法获取公钥"
                }
                
            case .failure(let error):
                print("❌ 签名失败: \(error.localizedDescription)")
                verificationResult = "❌ 签名失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func importPrivateKeyAction() {
        p256Signer.importPrivateKey(importPrivateKey) { result in
            switch result {
            case .success:
                print("✅ 私钥导入成功")
                showImportSheet = false
                importPrivateKey = ""
                loadPublicKey()
            case .failure(let error):
                print("❌ 私钥导入失败: \(error.localizedDescription)")
            }
        }
    }
}

// 导出私钥视图
struct ExportPrivateKeyView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var p256Signer = P256Signer.shared
    @State private var copied = false
    
    let privateKey: String
    
    var actualPrivateKey: String {
        p256Signer.exportPrivateKey() ?? "无私钥"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ 安全警告")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("私钥非常重要，请妥善保管！\n• 不要分享给任何人\n• 建议离线保存\n• 丢失无法恢复")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("私钥 (Base64)")
                        .font(.headline)
                    
                    Text(actualPrivateKey)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                
                Button(action: {
                    UIPasteboard.general.string = actualPrivateKey
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }) {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "已复制" : "复制私钥")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(copied ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("导出私钥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 导入私钥视图
struct ImportPrivateKeyView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var importText: String
    let onImport: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("导入说明")
                        .font(.headline)
                    
                    Text("粘贴之前导出的私钥 (Base64 格式)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                TextEditor(text: $importText)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(height: 200)
                
                Button(action: {
                    onImport()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("导入")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(importText.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(importText.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("导入私钥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DebugInfoSection: View {
    let title: String
    let content: String
    @Binding var copiedItem: String
    
    var isCopied: Bool {
        copiedItem == title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .textSelection(.enabled)
            
            Button(action: {
                UIPasteboard.general.string = content
                copiedItem = title
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if copiedItem == title {
                        copiedItem = ""
                    }
                }
            }) {
                HStack {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    Text(isCopied ? "已复制" : "复制")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCopied ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}
