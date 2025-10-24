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
    private var realm: Realm?
    
    private init() {}
    
    func initialize() {
        do {
            let config = Realm.Configuration(schemaVersion: 1)
            Realm.Configuration.defaultConfiguration = config
            realm = try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    private var instance: Realm {
        guard let realm = realm else {
            fatalError("Realm not initialized.")
        }
        return realm
    }
    
    func save<T: Object>(_ object: T) {
        do {
            try instance.write {
                instance.add(object, update: .modified)
            }
        } catch {
            print("Realm save error: \(error)")
        }
    }
    
    func fetchAll<T: Object>(_ type: T.Type) -> Results<T> {
        return instance.objects(type)
    }
    
    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) {
        guard let object = instance.object(ofType: type, forPrimaryKey: key) else {
            print("Realm delete: object not found for key \(key)")
            return
        }
        
        do {
            try instance.write {
                instance.delete(object)
            }
        } catch {
            print("Realm delete error: \(error)")
        }
    }
    
    func update<T: Object>(_ object: T, block: () -> Void) {
        do {
            try instance.write {
                block()
            }
        } catch {
            print("Realm update error: \(error)")
        }
    }
}
