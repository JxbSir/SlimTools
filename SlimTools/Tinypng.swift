//
//  Tinypng.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/9.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Cocoa
import Foundation

class Tinypng {
    
    private let logFile = (Bundle.main.resourcePath ?? "") + "/slim.log"
    private let tinyedFile = (Bundle.main.resourcePath ?? "") + "/tinyed.log"
    private var tinyedFiles: [String] = []
    
    private let semaphore = DispatchSemaphore(value: 0)
    
    private let keys: [String] = [
        "jmU13Fw2fK6NfO92B2t82w6mMfirxK1mj",
        "bpq1e1MlgfxkpUgibf9xEeubyeO1ntrYi",
        "w0g132zBMeZwsKWtaYoVxnSSb1u4Zfqz5",
        "VJO1Aiu0H6EdLQhGHAsNd5WTI6zeoPRi1",
        "Tnl1vhHbyYxnOZCj8oHmdvCPcuDUbcf0d",
        "kaK1IRDXUQpAZeEL6KbGEjO8HAeqTQBhA"
    ]
    
    private var failedFiles: [String] = []
    
    init() {
        if FileManager.default.fileExists(atPath: tinyedFile), let handler = FileHandle(forReadingAtPath: tinyedFile) {
            let data = handler.readDataToEndOfFile()
            let log = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            tinyedFiles = log?.components(separatedBy: "\n") ?? []
            handler.closeFile()
        }
    }
    
    func start(dir: String) {
        print("启动资源压缩，正在扫描目录...")
        
        let result = Sort().fetchSorted(dir: dir)
        if result.files.count == 0 {
            print("发现\(result.files.count)个图片，目录<\(dir)>")
            return
        }
        print("\(result.files.count)个图片排序完成，开始连接Tinypng")
        
        var keyIndex: Int = 0
        var fileIndex: Int = 0
        
        let totalCount = result.files.count
        while fileIndex < totalCount {
            let file = result.files[fileIndex]
            
            let progress = Double(fileIndex + 1) * 10000 / Double(totalCount) / 100.0
            guard !tinyedFiles.contains(file) else {
                let progressString = String.init(format: "进度：%.2f%%", progress)
                print("\(file)已压缩，跳过，\(progressString)...")
                return
            }
            if keyIndex < keys.count {
                let key = "api:" + keys[keyIndex]
                let keyData = key.data(using: String.Encoding.utf8)
                if let base64String = keyData?.base64EncodedString() {
                    self.upload(file: file, with: "Basic " + base64String, progress: progress) { (success) in
                        if success {
                            fileIndex += 1
                            self.tinyedFiles.append(file)
                        } else {
                            keyIndex += 1
                            self.failedFiles.append(file)
                        }
                        self.semaphore.signal()
                    }
                    _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                }
            } else {
                print("key 用完了")
            }
        }
  
        let progress = Double(result.files.count - failedFiles.count) * 10000 / Double(result.files.count) / 100
        let log = String(format: "所有图片压缩完毕，成功率：%.2f%%", progress)
        print("\(log)")
        
        self.tinyed()
    }
    
    private func upload(file: String, with key: String, progress: Double, completion: @escaping (Bool) -> Void) {
        let progressString = String(format: "进度：%.2f%%", progress)
        let fileUrl = URL(fileURLWithPath: file)
        let request = NSMutableURLRequest(url: URL(string: "https://api.tinify.com/shrink")!)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(key, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.uploadTask(with: request as URLRequest, fromFile: fileUrl, completionHandler: { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            if error == nil {
                //上传成功
                guard let allHeaderFields = httpResponse?.allHeaderFields, let location = allHeaderFields["Location"] as? String, let url = URL(string: location) else {
                    print("\(file) 上传失败，切换Api Key\n", terminator: "")
                    completion(false)
                    return
                }
                
                var ratio: String = "压缩率：0%"
                if let data = data,
                    let result = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any],
                    let output = result?["output"] as? [String: Any],
                    let _ratio = output["ratio"] as? Double  {
                    ratio = String(format: "压缩率：%.2f%%", _ratio * 100)
                }
                
                let requestCompress = NSMutableURLRequest(url: url)
                requestCompress.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                requestCompress.setValue(key, forHTTPHeaderField: "Authorization")
                let taskCompress = URLSession.shared.dataTask(with: requestCompress as URLRequest, completionHandler: { (data, respinse, error) in

                    guard error == nil else {
                        completion(false)
                        print("\(file) 压缩失败 切换ApiKey\n", terminator: "")
                        return
                    }
                    
                    try? data?.write(to: fileUrl, options: .atomic)
                    
                    print("\(file) 压缩成功(\(ratio) \(progressString)\n", terminator: "")
                    
                    completion(true)
                })
                taskCompress.resume()
                
            } else {
                print("上传失败可能超过限制，切换Api Key\n", terminator: "")
                completion(false)
            }
        })
        task.resume()
    }
    
    private func tinyed() {
        let log = self.tinyedFiles.joined(separator: "\n")
        
        if !FileManager.default.fileExists(atPath: tinyedFile) {
            FileManager.default.createFile(atPath: tinyedFile, contents: log.data(using: String.Encoding.utf8), attributes: nil)
        } else {
            try? log.write(toFile: tinyedFile, atomically: true, encoding: String.Encoding.utf8)
        }
    }
}
