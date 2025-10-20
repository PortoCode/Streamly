//
//  RealmManager.swift
//  Streamly
//
//  Created by Rodrigo Porto on 19/10/25.
//

import Foundation
import RealmSwift

final class RealmManager {
    static let shared = RealmManager()
    private init() {}
    
    func setupRealm() {
        let config = Realm.Configuration(schemaVersion: 1)
        Realm.Configuration.defaultConfiguration = config
        _ = try? Realm()
    }
}
