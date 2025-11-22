//
//  ContentView.swift
//  Polarwing
//
//  Created by Harold on 2025/11/22.
//

import SwiftUI

struct ContentView: View {
    @State private var isOnboardingComplete = UserDefaults.standard.string(forKey: "username") != nil
    
    var body: some View {
        if isOnboardingComplete {
            MainTabView()
        } else {
            OnboardingView(isOnboardingComplete: $isOnboardingComplete)
        }
    }
}

#Preview {
    ContentView()
}
