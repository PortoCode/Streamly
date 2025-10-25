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
    
    private init() {
        let config = Realm.Configuration(schemaVersion: 1)
        Realm.Configuration.defaultConfiguration = config
    }
    
    private func realm() throws -> Realm {
        try Realm()
    }
    
    func save<T: Object>(_ object: T) {
        do {
            let realm = try realm()
            try realm.write {
                realm.add(object, update: .modified)
            }
        } catch {
            print("Realm save error: \(error)")
        }
    }
    
    func fetchAll<T: Object>(_ type: T.Type) -> Results<T> {
        do {
            let realm = try realm()
            return realm.objects(type)
        } catch {
            print("Realm fetch error: \(error)")
            let fallback = try! Realm()
            return fallback.objects(type)
        }
    }
    
    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) {
        do {
            let realm = try realm()
            if let object = realm.object(ofType: type, forPrimaryKey: key) {
                try realm.write {
                    realm.delete(object)
                }
            }
        } catch {
            print("Realm delete error: \(error)")
        }
    }
    
    func update<T: Object>(_ object: T, block: () -> Void) {
        do {
            let realm = try realm()
            try realm.write {
                block()
            }
        } catch {
            print("Realm update error: \(error)")
        }
    }
}
