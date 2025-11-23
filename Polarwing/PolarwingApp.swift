//
//  PolarwingApp.swift
//  Polarwing
//
//  Created by Harold on 2025/11/22.
//

import SwiftUI

@main
struct PolarwingApp: App {
    init() {
        // 应用启动时立即触发网络权限请求
        Task {
            await Self.requestNetworkPermission()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    // 启动时发送简单的网络请求以触发权限申请
    private static func requestNetworkPermission() async {
        guard let url = URL(string: "https://api-polarwing.ngrok.app/api/v1/health") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ 网络连接正常 - 状态码: \(httpResponse.statusCode)")
            }
        } catch {
            // 忽略错误，只是为了触发网络权限请求
            print("⚠️ 网络预检测: \(error.localizedDescription)")
        }
    }
}
