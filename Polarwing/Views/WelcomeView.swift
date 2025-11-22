//
//  WelcomeView.swift
//  Polarwing
//
//  Created on 2025-11-22.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcome: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Hello World")
                .font(.system(size: 48, weight: .bold))
            
            Button(action: {
                showWelcome = false
            }) {
                Text("进入")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
    }
}
