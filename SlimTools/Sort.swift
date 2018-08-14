//
//  Sort.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/14.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Cocoa

private let sizeOfG: Double = 1000 * 1000 * 1000
private let sizeOfM: Double = 1000 * 1000
private let sizeOfK: Double = 1000

class Sort {
    private let logFile = (Bundle.main.resourcePath ?? "") + "/slim.log"
    
    private var logs: NSMutableString = NSMutableString()
    
    func start(dir: String) {
        if FileManager.default.fileExists(atPath: logFile) {
            try? FileManager.default.removeItem(atPath: logFile)
        }
        
        print("启动资源文件排序检测，正在扫描目录...")
        logs.append("启动资源文件排序检测，正在扫描目录...\n")
        var list: [String] = []
        var count: Int = 0
        FileHelper.shared.fetchAllPNGs(with: dir, list: &list, count: &count)
        if list.count == 0 {
            print("扫描到\(count)个文件，发现\(list.count)个PNG图片，目录<\(dir)>")
            logs.append("扫描到\(count)个文件，发现\(list.count)个PNG图片，目录<\(dir)>\n")
            return
        }
        print("扫描到\(count)个文件，发现\(list.count)个PNG图片，开始排序...")
        logs.append("扫描到\(count)个文件，发现\(list.count)个PNG图片，开始排序...\n")
        
        var dicFileAttr: [String: Double] = [:]
        
        let results = list.sorted { (file1, file2) -> Bool in
            guard let attr1 = try? FileManager.default.attributesOfItem(atPath: file1),
                let attr2 = try? FileManager.default.attributesOfItem(atPath: file2),
                let size1 = attr1[FileAttributeKey.size] as? NSNumber,
                let size2 = attr2[FileAttributeKey.size] as? NSNumber else {
                return false
            }
            
            dicFileAttr.updateValue(size1.doubleValue, forKey: file1)
            dicFileAttr.updateValue(size2.doubleValue, forKey: file2)
  
            return size1.doubleValue > size2.doubleValue
            
        }
        
        results.forEach { (file) in
            if let size = dicFileAttr[file] {
                logs.append("\(getSizeString(size))    \(file)\n")
            } else {
                logs.append("unknown    \(file)\n")
            }
        }
        
        print("排序完成")
        
        if !FileManager.default.fileExists(atPath: logFile) {
            FileManager.default.createFile(atPath: logFile, contents: logs.data(using: String.Encoding.utf8.rawValue), attributes: nil)
        } else {
            try? logs.write(toFile: logFile, atomically: true, encoding: 0)
        }
        
    }
    
    private func getSizeString(_ size: Double) -> String {
        if size > sizeOfG {
            return String(format: "%.2fG", size/sizeOfG)
        } else if size > sizeOfM {
            return String(format: "%.2fM", size/sizeOfM)
        } else if size > sizeOfK {
            return String(format: "%.2fK", size/sizeOfK)
        }
        return String(format: "%.2fB", size)
    }
}
