//
//  PasskeyManager.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import Foundation
import CryptoKit
import Security

class PasskeyManager: NSObject, ObservableObject {
    static let shared = PasskeyManager()
    
    @Published var isAuthenticated = false
    @Published var publicKey: Data?
    @Published var privateKey: P256.Signing.PrivateKey?
    @Published var lastSignature: Data?
    
    private let privateKeyTag = "com.polarwing.p256.privatekey"
    private let publicKeyTag = "com.polarwing.p256.publickey"
    
    private override init() {
        super.init()
        // 加载已有的密钥对
        if let savedPrivateKey = loadPrivateKey() {
            self.privateKey = savedPrivateKey
            self.publicKey = savedPrivateKey.publicKey.x963Representation
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Key Management
    
    // 生成 P256 密钥对
    func generateKeyPair(completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            // 生成新的私钥
            let privateKey = P256.Signing.PrivateKey()
            
            // 获取公钥
            let publicKeyData = privateKey.publicKey.x963Representation
            
            // 保存到 Keychain
            try savePrivateKey(privateKey)
            
            // 更新状态
            self.privateKey = privateKey
            self.publicKey = publicKeyData
            self.isAuthenticated = true
            
            print("✅ 成功生成 P256 密钥对")
            print("  - 公钥长度: \(publicKeyData.count) 字节")
            print("  - 公钥 (Hex): \(publicKeyData.map { String(format: "%02x", $0) }.joined())")
            print("  - 公钥 (Base64): \(publicKeyData.base64EncodedString())")
            
            completion(.success(publicKeyData))
            
        } catch {
            print("❌ 密钥生成失败: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // 使用私钥对消息签名
    func signMessage(_ message: String, completion: @escaping (Result<SignatureResult, Error>) -> Void) {
        guard let messageData = message.data(using: .utf8) else {
            completion(.failure(NSError(domain: "PasskeyManager", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Invalid message"])))
            return
        }
        
        guard let privateKey = self.privateKey else {
            completion(.failure(NSError(domain: "PasskeyManager", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Private key not found. Please generate key pair first."])))
            return
        }
        
        do {
            // 计算消息的 SHA256 hash
            let messageHash = SHA256.hash(data: messageData)
            let hashData = Data(messageHash)
            
            // 使用私钥签名
            let signature = try privateKey.signature(for: messageData)
            
            // 转换为 DER 格式
            let derSignature = signature.derRepresentation
            
            // 保存最后的签名
            self.lastSignature = derSignature
            
            print("✅ 签名成功")
            print("  - 消息: \(message)")
            print("  - 消息 Hash: \(hashData.map { String(format: "%02x", $0) }.joined())")
            print("  - 签名长度: \(derSignature.count) 字节")
            print("  - 签名 (Hex): \(derSignature.map { String(format: "%02x", $0) }.joined())")
            print("  - 签名 (Base64): \(derSignature.base64EncodedString())")
            
            let result = SignatureResult(
                signature: derSignature,
                message: messageData,
                messageHash: hashData
            )
            
            completion(.success(result))
            
        } catch {
            print("❌ 签名失败: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // 验证签名
    func verifySignature(signature: Data, message: Data, publicKey: Data) -> Bool {
        do {
            // 从公钥数据创建 P256 公钥
            let p256PublicKey = try P256.Signing.PublicKey(x963Representation: publicKey)
            
            // 从 DER 格式创建签名
            let ecdsaSignature = try P256.Signing.ECDSASignature(derRepresentation: signature)
            
            // 验证签名
            let isValid = p256PublicKey.isValidSignature(ecdsaSignature, for: message)
            
            print("🔐 签名验证结果: \(isValid ? "✅ 有效" : "❌ 无效")")
            
            return isValid
            
        } catch {
            print("❌ 签名验证失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Import/Export
    
    // 导出私钥（用于备份）
    func exportPrivateKey() -> String? {
        guard let privateKey = self.privateKey else {
            return nil
        }
        
        // 返回原始私钥数据的 Base64 编码
        return privateKey.rawRepresentation.base64EncodedString()
    }
    
    // 导入私钥（用于恢复）
    func importPrivateKey(_ base64String: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let privateKeyData = Data(base64Encoded: base64String) else {
            completion(.failure(NSError(domain: "PasskeyManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid private key format"])))
            return
        }
        
        do {
            // 从原始数据创建私钥
            let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
            
            // 保存到 Keychain
            try savePrivateKey(privateKey)
            
            // 更新状态
            self.privateKey = privateKey
            self.publicKey = privateKey.publicKey.x963Representation
            self.isAuthenticated = true
            
            print("✅ 私钥导入成功")
            
            completion(.success(privateKey.publicKey.x963Representation))
            
        } catch {
            print("❌ 私钥导入失败: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Keychain Operations
    
    private func savePrivateKey(_ privateKey: P256.Signing.PrivateKey) throws {
        // 删除旧密钥
        deletePrivateKey()
        
        let privateKeyData = privateKey.rawRepresentation
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: privateKeyTag,
            kSecValueData as String: privateKeyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NSError(domain: "PasskeyManager", code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to save private key to Keychain: \(status)"])
        }
        
        print("✅ 私钥已保存到 Keychain")
    }
    
    private func loadPrivateKey() -> P256.Signing.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: privateKeyTag,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let privateKeyData = result as? Data,
              let privateKey = try? P256.Signing.PrivateKey(rawRepresentation: privateKeyData) else {
            print("⚠️ 未找到已保存的私钥")
            return nil
        }
        
        print("✅ 从 Keychain 加载私钥成功")
        return privateKey
    }
    
    private func deletePrivateKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: privateKeyTag
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func getSavedPublicKey() -> Data? {
        return privateKey?.publicKey.x963Representation
    }
}

// 签名结果
struct SignatureResult {
    let signature: Data        // ECDSA 签名 (DER 编码)
    let message: Data          // 原始消息
    let messageHash: Data      // SHA256(message)
    
    // 转换为十六进制字符串（用于链上交互）
    func toHexStrings() -> [String: String] {
        return [
            "signature": signature.map { String(format: "%02x", $0) }.joined(),
            "message": message.map { String(format: "%02x", $0) }.joined(),
            "messageHash": messageHash.map { String(format: "%02x", $0) }.joined()
        ]
    }
    
    // 生成 Sui Move 调用示例
    func toSuiMoveArgs(publicKey: Data) -> String {
        let hex = toHexStrings()
        let pkHex = publicKey.map { String(format: "%02x", $0) }.joined()
        
        return """
        // Sui Move 验证函数示例:
        public fun verify_signature(
            signature: vector<u8>,     // 0x\(hex["signature"]!)
            message: vector<u8>,        // 0x\(hex["message"]!)
            public_key: vector<u8>,     // 0x\(pkHex)
        ): bool {
            // 使用 Sui 的 secp256r1_verify 验证签名
            // 签名采用 DER 编码，公钥为 65 字节（0x04 + x + y）
            sui::crypto::secp256r1_verify(&signature, &public_key, &message)
        }
        """
    }
}
