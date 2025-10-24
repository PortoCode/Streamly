//
//  StreamlyApp.swift
//  Streamly
//
//  Created by Rodrigo Porto on 17/10/25.
//

import SwiftUI

@main
struct StreamlyApp: App {
    init() {
        RealmManager.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            VideoListView()
        }
    }
}
