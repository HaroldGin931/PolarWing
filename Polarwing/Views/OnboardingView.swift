//
//  OnboardingView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var p256Signer = P256Signer.shared
    @Binding var isOnboardingComplete: Bool
    
    // Mint green theme color
    private let themeColor = Color(red: 172/255, green: 237/255, blue: 228/255)
    
    @State private var username = ""
    @State private var isCreatingPasskey = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "camera.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(themeColor)
                
                Text("欢迎来到 Polarwing")
                    .font(.system(size: 32, weight: .bold))
                
                Text("设置你的用户名开始使用")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 20) {
                TextField("输入用户名", text: $username)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: setupAccount) {
                    HStack {
                        if isCreatingPasskey {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("开始使用")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(username.isEmpty ? Color.gray : themeColor)
                    .cornerRadius(16)
                }
                .disabled(username.isEmpty || isCreatingPasskey)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .alert("设置失败", isPresented: $showError) {
            Button("重试", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func setupAccount() {
        isCreatingPasskey = true
        
        // 生成 P256 密钥对
        p256Signer.generateKeyPair { result in
            switch result {
            case .success(let publicKey):
                print("🔑 成功生成密钥对")
                print("  - 公钥 (Base64): \(publicKey.base64EncodedString())")
                print("  - 公钥长度: \(publicKey.count) 字节")
                
                // 创建需要签名的消息
                let action = "upload"
                let timestamp = Int(Date().timeIntervalSince1970)
                let nonce = Int.random(in: 1...Int.max)
                let message = "\(action)\(timestamp)\(nonce)"
                
                print("📝 构建签名消息")
                print("  - action: \(action)")
                print("  - timestamp: \(timestamp)")
                print("  - nonce: \(nonce)")
                print("  - 完整消息: \(message)")
                
                // 获取 Sui 地址
                guard let suiAddress = p256Signer.generateSuiAddress() else {
                    isCreatingPasskey = false
                    errorMessage = "生成地址失败"
                    showError = true
                    return
                }
                
                print("🏠 生成 Sui 地址: \(suiAddress)")
                
                // 签名
                p256Signer.signMessage(message) { signResult in
                    switch signResult {
                    case .success(let signatureResult):
                        print("✍️ 签名成功")
                        print("  - 签名 (Base64): \(signatureResult.signature.base64EncodedString())")
                        print("  - 签名长度: \(signatureResult.signature.count) 字节")
                        
                        print("\n📋 准备发送的完整数据:")
                        print("  - nickname: \(username)")
                        print("  - avatarUrl: TBD")
                        print("  - bio: TBD")
                        print("  - suiAddress: \(suiAddress)")
                        print("  - publicKey: \(publicKey.base64EncodedString())")
                        print("  - signature: \(signatureResult.signature.base64EncodedString())")
                        print("  - action: \(action)")
                        print("  - timestamp: \(timestamp)")
                        print("  - nonce: \(nonce)")
                        
                        // 调用 API
                        Task {
                            do {
                                let profile = try await APIService.shared.updateProfile(
                                    nickname: username,
                                    avatarUrl: "TBD",
                                    bio: "TBD",
                                    suiAddress: suiAddress,
                                    publicKey: publicKey.base64EncodedString(),
                                    signature: signatureResult.signature.base64EncodedString(),
                                    action: action,
                                    timestamp: timestamp,
                                    nonce: nonce
                                )
                                
                                // 保存用户名和地址
                                await MainActor.run {
                                    UserDefaults.standard.set(username, forKey: "username")
                                    UserDefaults.standard.set(suiAddress, forKey: "suiAddress")
                                    print("✅ 账户设置成功")
                                    print("  - 昵称: \(profile.nickname)")
                                    print("  - 地址: \(profile.address)")
                                    isCreatingPasskey = false
                                    isOnboardingComplete = true
                                }
                            } catch {
                                await MainActor.run {
                                    isCreatingPasskey = false
                                    errorMessage = "注册失败: \(error.localizedDescription)"
                                    showError = true
                                }
                            }
                        }
                        
                    case .failure(let error):
                        isCreatingPasskey = false
                        errorMessage = "签名失败: \(error.localizedDescription)"
                        showError = true
                    }
                }
                
            case .failure(let error):
                isCreatingPasskey = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
