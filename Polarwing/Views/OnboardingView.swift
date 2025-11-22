//
//  OnboardingView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @StateObject private var passkeyManager = PasskeyManager.shared
    @Binding var isOnboardingComplete: Bool
    
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
                    .foregroundColor(.blue)
                
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
                    .background(username.isEmpty ? Color.gray : Color.blue)
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
        
        // 保存用户名
        UserDefaults.standard.set(username, forKey: "username")
        
        // 创建Passkey
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first else {
            isCreatingPasskey = false
            return
        }
        
        passkeyManager.createPasskey(anchor: window) { result in
            isCreatingPasskey = false
            
            switch result {
            case .success(let credentialID):
                print("账户设置成功: \(credentialID.base64EncodedString())")
                isOnboardingComplete = true
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
