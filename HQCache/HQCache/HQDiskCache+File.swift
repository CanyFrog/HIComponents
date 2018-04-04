//
//  HQDiskCache+File.swift
//  HQCache
//
//  Created by Magee Huang on 4/4/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//


// MARK: - File manager helper
internal extension HQDiskCache {
    func convertToUrl(_ name: String) -> URL {
        return URL(fileURLWithPath: "\(dataPath)/\(name)")
    }
    
    func save(data: Data, withFilename name: String) throws {
        try data.write(to: convertToUrl(name))
    }
    
    func read(dataWithFilename name: String) throws -> Data {
        return try Data(contentsOf: convertToUrl(name))
    }
    
    func delete(fileWithFilename name: String) throws {
        try FileManager.default.removeItem(at: convertToUrl(name))
    }
    
    func moveAllFileToTrash() throws {
        let tmpPath = "\(trashPath)/\(UUID().uuidString)"
        try FileManager.default.moveItem(atPath: dataPath, toPath: tmpPath) // move file to trash temp directory
        try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    func emptyTrashInBackground() {
        let trash = trashPath!
        backgroundTrashQueue.async {
            let fileManager = FileManager()
            if let trashs = try? fileManager.contentsOfDirectory(atPath: trash) {
                let _ = trashs.map{ p in
                    try? fileManager.removeItem(atPath: trash.appending(p))
                }
            }
        }
    }
}
