//
//  FileManager.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/14.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Cocoa

extension FileManager {
    
    public func createDirectoryIfNotExist(_ path: String, attributes: [FileAttributeKey : Any]? = nil) -> Bool {
        
        var isDirectory : ObjCBool = false
        let fileExist = fileExists(atPath: path, isDirectory: &isDirectory)
        
        if !fileExist || !isDirectory.boolValue {
            do {
                // file exist but not directory, remove the file first
                if fileExist {
                    try removeItem(atPath: path)
                }
                
                // create directory
                try createDirectory(atPath: path, withIntermediateDirectories: true, attributes: attributes)
            }
            catch let error {
                print("\(error)")
                return false
            }
        }
        
        return true
    }
    
    public func createFileIfNotExist(_ path: String, attributes: [FileAttributeKey : Any]? = nil) -> Bool {
        
        var isDirectory: ObjCBool = false
        let fileExist = fileExists(atPath: path, isDirectory: &isDirectory)
        
        if !fileExist || isDirectory.boolValue {
            do {
                // file exist but is directory, remove the directory first
                if fileExist {
                    try removeItem(atPath: path)
                }
                
                // create file
                return createFile(atPath: path, contents: nil, attributes: attributes)
            }
            catch let error {
                print("\(error)")
                return false
            }
        }
        
        return true
    }
    
}
