//
//  MD5.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/9.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Cocoa

class MD5 {

    private let logFile = (Bundle.main.resourcePath ?? "") + "/slim.log"
    
    private var logs: NSMutableString = NSMutableString()
    
    func start(dir: String) {
        if FileManager.default.fileExists(atPath: logFile) {
            try? FileManager.default.removeItem(atPath: logFile)
        }
        
        print("启动MD5检测，正在扫描目录...")
        logs.append("启动MD5检测，正在扫描目录...\n")
        var list: [String] = []
        var count: Int = 0
        FileHelper.shared.fetchAllPNGs(with: dir, list: &list, count: &count)
        if list.count == 0 {
            print("扫描到\(count)个文件，发现\(list.count)个图片，目录<\(dir)>")
            logs.append("扫描到\(count)个文件，发现\(list.count)个图片，目录<\(dir)>\n")
            return
        }
        print("扫描到\(count)个文件，发现\(list.count)个图片，开始分析MD5...")
        logs.append("扫描到\(count)个文件，发现\(list.count)个图片，开始分析MD5...\n")
        
        var dicFiles: [String: [String]] = [:]
        var duplicateMD5: Set<String> = []
        
        list.enumerated().forEach { (offset, path) in
            let progress = Double(offset + 1) * 10000 / Double(list.count)
            let log = String(format: "分析MD5进度：%.2f%%", progress / 100)
            if offset < list.count - 1 {
                print("\(log) \r", terminator: "")
            } else {
                print("\(log) \n", terminator: "")
            }
            if let md5 = self.md5(path: path) {
                if var files = dicFiles[md5] {
                    files.append(path)
                    dicFiles.updateValue(files, forKey: md5)
                    if files.count > 1 {
                        duplicateMD5.insert(md5)
                    }
                } else {
                    dicFiles.updateValue([path], forKey: md5)
                }
            }
        }
        
        if duplicateMD5.count > 0 {
            var log = ""
            duplicateMD5.forEach { (md5) in
                logs.append("md5:\(md5)\n")
                log.append("\n")
                log.append(md5)
                log.append("\n")
                if let files = dicFiles[md5] {
                    files.forEach { (file) in
                        logs.append("\(file)\n")
                        log.append(file)
                        log.append("\n")
                    }
                }
                log.append("\n")
                logs.append("\n")
            }
            print("MD5分析完成，发现\(duplicateMD5.count)个MD5重复资源\n\(log)")
            logs.append("MD5分析完成，发现\(duplicateMD5.count)个MD5重复资源\n")
        } else {
            print("MD5分析完成，未发现MD5重复资源")
            logs.append("MD5分析完成，未发现MD5重复资源")
        }
        
        if !FileManager.default.fileExists(atPath: logFile) {
            FileManager.default.createFile(atPath: logFile, contents: logs.data(using: String.Encoding.utf8.rawValue), attributes: nil)
        } else {
            try? logs.write(toFile: logFile, atomically: true, encoding: 0)
        }
    }
    
    func md5(path: String) -> String? {
        
        let url = URL(fileURLWithPath: path)
        
        let bufferSize = 1024 * 1024
        
        do {
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }
            
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            
            while case let data = file.readData(ofLength: bufferSize), data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0, CC_LONG(data.count))
                }
            }
            
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_MD5_Final($0, &context)
            }
            
            return digest.map { String(format: "%02hhx", $0) }.joined()
            
        } catch {
            print("Cannot open file:", error.localizedDescription)
            return nil
        }
    }
}
