//
//  ContentView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var carbonCalculatorViewModel = CarbonCalculatorViewModel()
    @StateObject private var learnViewModel = LearnViewModel()
    @StateObject private var scanViewModel = ScanViewModel()
    
    var body: some View {
        TabView {
            HomeView(carbonCalculatorViewModel: carbonCalculatorViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CarbonCalculatorView(viewModel: carbonCalculatorViewModel)
                .tabItem {
                    Image(systemName: "calculator.fill")
                    Text("Calculator")
                }
            
            ScanView(viewModel: scanViewModel)
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Scan")
                }
            
            RecyclingView()
                .tabItem {
                    Image(systemName: "arrow.3.trianglepath")
                    Text("Recycling")
                }
            
            LearnView(viewModel: learnViewModel)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Learn")
                }
        }
        .accentColor(.green)
    }
}

#Preview {
    ContentView()
}
