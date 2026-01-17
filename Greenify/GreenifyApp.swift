//
//  GreenifyApp.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

@main
struct GreenifyApp: App {
    
    init() {
        // Initialize Google Maps Platform on app launch
        #if canImport(GoogleMaps)
        if !Config.googleMapsAPIKey.isEmpty && Config.googleMapsAPIKey != "YOUR_GOOGLE_MAPS_API_KEY_HERE" {
            GMSServices.provideAPIKey(Config.googleMapsAPIKey)
        }
        #endif
        
        // Initialize Google Sign-In configuration
        #if canImport(GoogleSignIn)
        if !Config.googleClientID.isEmpty && Config.googleClientID != "YOUR_GOOGLE_CLIENT_ID_HERE" {
            let config = GIDConfiguration(clientID: Config.googleClientID)
            GIDSignIn.sharedInstance.configuration = config
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if canImport(GoogleMaps)
import GoogleMaps
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
