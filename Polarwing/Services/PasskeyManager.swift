//
//  PasskeyManager.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import Foundation
import AuthenticationServices

class PasskeyManager: NSObject, ObservableObject {
    static let shared = PasskeyManager()
    
    @Published var isAuthenticated = false
    @Published var currentCredentialID: String?
    
    private let rpID = "api-polarwing.ngrok.app"
    private let userID = "new user"
    
    private override init() {
        super.init()
    }
    
    // 创建新的Passkey
    func createPasskey(anchor: ASPresentationAnchor, completion: @escaping (Result<Data, Error>) -> Void) {
        let challenge = generateChallenge()
        let userIDData = userID.data(using: .utf8)!
        
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        
        let registrationRequest = platformProvider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: userID,
            userID: userIDData
        )
        
        let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
        
        self.registrationCompletion = completion
    }
    
    // 使用已有的Passkey进行认证
    func authenticateWithPasskey(anchor: ASPresentationAnchor, completion: @escaping (Result<Data, Error>) -> Void) {
        let challenge = generateChallenge()
        
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpID)
        
        let assertionRequest = platformProvider.createCredentialAssertionRequest(challenge: challenge)
        
        let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
        
        self.authenticationCompletion = completion
    }
    
    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
    
    private var registrationCompletion: ((Result<Data, Error>) -> Void)?
    private var authenticationCompletion: ((Result<Data, Error>) -> Void)?
}

extension PasskeyManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // Passkey注册成功
            let credentialID = credential.credentialID
            self.currentCredentialID = credentialID.base64EncodedString()
            self.isAuthenticated = true
            
            // 保存credential ID
            saveCredentialID(credentialID)
            
            registrationCompletion?(.success(credentialID))
            registrationCompletion = nil
            
        } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // Passkey认证成功
            let credentialID = credential.credentialID
            self.currentCredentialID = credentialID.base64EncodedString()
            self.isAuthenticated = true
            
            authenticationCompletion?(.success(credentialID))
            authenticationCompletion = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        registrationCompletion?(.failure(error))
        authenticationCompletion?(.failure(error))
        registrationCompletion = nil
        authenticationCompletion = nil
    }
    
    private func saveCredentialID(_ credentialID: Data) {
        UserDefaults.standard.set(credentialID, forKey: "passkey_credential_id")
    }
    
    func getSavedCredentialID() -> Data? {
        return UserDefaults.standard.data(forKey: "passkey_credential_id")
    }
}

extension PasskeyManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
