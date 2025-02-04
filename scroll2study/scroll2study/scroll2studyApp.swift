//
//  scroll2studyApp.swift
//  scroll2study
//
//  Created by Harm on 2/3/25.
//

import FirebaseCore
import SwiftUI
import os

// Create a logger
private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study", category: "AppLifecycle")

@main
struct scroll2studyApp: App {
    init() {
        logger.info("📱 App initialization started")
        do {
            FirebaseApp.configure()
            logger.info("🔥 Firebase successfully configured")
        } catch {
            logger.error("❌ Firebase configuration failed: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    logger.info("🎨 ContentView appeared")
                }
        }
    }
}
