//
//  StreamlyApp.swift
//  Streamly
//
//  Created by Rodrigo Porto on 17/10/25.
//

import SwiftUI

@main
struct StreamlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            VideoListView()
        }
    }
}
