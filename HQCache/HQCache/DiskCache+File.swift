//
//  DiskCache+File.swift
//  HQCache
//
//  Created by Magee Huang on 4/4/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//


// MARK: - File manager helper
internal extension DiskCache {
    func convertToUrl(_ name: String) -> URL {
        return dataPath.appendingPathComponent(name)
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
    
    func moveAllFileToTrash() {
        let tmpPath = trashPath.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.moveItem(at: dataPath, to: tmpPath) // move file to trash temp directory
        try? FileManager.default.createDirectory(at: dataPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    func emptyTrashInBackground() {
        let trash = trashPath
        backgroundTrashQueue.async {
            let fileManager = FileManager()
            if let trashs = try? fileManager.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.init(rawValue: 0)) {
                let _ = trashs.map{ p in
                    try? fileManager.removeItem(at: p)
                }
            }
        }
    }
}
