//
//  ContentView.swift
//  Polarwing
//
//  Created by Harold on 2025/11/22.
//

import SwiftUI

struct ContentView: View {
    @State private var showWelcome = true
    
    var body: some View {
        if showWelcome {
            WelcomeView(showWelcome: $showWelcome)
        } else {
            MainTabView()
        }
    }
}

#Preview {
    ContentView()
}
