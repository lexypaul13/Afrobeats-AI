//
//  Afrobeats_AIApp.swift
//  Afrobeats AI
//
//  Created by Alex Paul on 6/9/24.
//

import SwiftUI
import Firebase
@main
struct Afrobeats_AIApp: App {
    init() {
            FirebaseApp.configure()
        }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
