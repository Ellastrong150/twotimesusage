//
//  twotimesusageApp.swift
//  twotimesusage
//
//  Created by Peter Leung on 15/03/2026.
//

import SwiftUI
import WidgetKit

@main
struct twotimesusageApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
