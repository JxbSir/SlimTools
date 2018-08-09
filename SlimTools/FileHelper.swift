//
//  FileHelper.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/9.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Cocoa

class FileHelper {

    static let shared = FileHelper()
    
    private init() {
        
    }
    
    func fetchAllPNGs(with path: String, list: inout [String], count: inout Int) {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            return
        }
        
        if let dirArray = try? fileManager.contentsOfDirectory(atPath: path) {
            dirArray.forEach { (name) in
                let subpath = "\(path)/\(name)"
                var issubDir: ObjCBool = false
                if fileManager.fileExists(atPath: subpath, isDirectory: &issubDir), issubDir.boolValue {
                    fetchAllPNGs(with: subpath, list: &list, count: &count)
                } else {
                    count += 1
                    let log = "已扫描\(count)个文件\r"
                    print("\(log) \r", terminator: "")
                    
                    if URL(fileURLWithPath: path).appendingPathComponent(name).pathExtension.lowercased() == "png" {
                        list.append(subpath)
                    }
                }
            }
        }
//        var subPath: String? = nil
//        for str: String? in dirArray ?? [String?]() {
//            subPath = URL(fileURLWithPath: path ?? "").appendingPathComponent(str).absoluteString
//            var issubDir: ObjCBool = false
//            fileManager.fileExists(atPath: subPath ?? "", isDirectory: &issubDir)
//            showAllFile(withPath: subPath)
//        }
    }
}
