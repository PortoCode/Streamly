//
//  FileManager+Extensions.swift
//  Streamly
//
//  Created by Rodrigo Porto on 20/10/25.
//

import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    static func fileExists(withName name: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    static func localFileURL(for name: String) -> URL {
        return documentsDirectory.appendingPathComponent(name)
    }
    
    static func excludeFromBackup(url: URL) throws {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }
}
