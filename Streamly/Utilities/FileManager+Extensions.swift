//
//  FileManager+Extensions.swift
//  Streamly
//
//  Created by Rodrigo Porto on 20/10/25.
//

import Foundation

extension FileManager {
    static var applicationSupportDirectory: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    static var downloadsDirectory: URL {
        let folder = applicationSupportDirectory.appendingPathComponent(Constants.downloadsFolderName)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    static func fileExists(withName name: String) -> Bool {
        let fileURL = downloadsDirectory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    static func localFileURL(for name: String) -> URL {
        return downloadsDirectory.appendingPathComponent(name)
    }
    
    static func excludeFromBackup(url: URL) throws {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }
}
