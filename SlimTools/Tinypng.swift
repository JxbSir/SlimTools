//
//  Tinypng.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/9.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Cocoa

class Tinypng {

    private let semaphore = DispatchSemaphore(value: 0)
    
    private let keys: [String] = [
        "jmU13Fw2fK6NfO92B2t82w6mMfirxK1mj",
        "bpq1e1MlgfxkpUgibf9xEeubyeO1ntrYi",
        "w0g132zBMeZwsKWtaYoVxnSSb1u4Zfqz5",
        "VJO1Aiu0H6EdLQhGHAsNd5WTI6zeoPRi1",
        "Tnl1vhHbyYxnOZCj8oHmdvCPcuDUbcf0d"
    ]
    private var keyIndex: Int = 0
    
    private var failedFiles: [String] = []
    
    func start(dir: String) {
        print("启动资源压缩，正在扫描目录...")
        var list: [String] = []
        var count: Int = 0
        FileHelper.shared.fetchAllPNGs(with: dir, list: &list, count: &count)
        if list.count == 0 {
            print("扫描到\(count)个文件，发现\(list.count)个PNG图片，目录<\(dir)>")
            return
        }
        print("扫描到\(count)个文件，发现\(list.count)个PNG图片，开始连接Tinypng")
        
        list.enumerated().forEach { (offset, file) in
            let progress = Double(offset + 1) * 10000 / Double(list.count) / 100.0
            if keyIndex < keys.count {
                let key = "api:" + keys[keyIndex]
                let keyData = key.data(using: String.Encoding.utf8)
                if let base64String = keyData?.base64EncodedString() {
                    self.upload(file: file, with: "Basic " + base64String, progress: progress)
                    _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                }
            } else {
                print("key 用完了")
            }
            
        }
        
        let progress = Double(list.count - failedFiles.count) * 10000 / Double(list.count) / 100
        let log = String(format: "所有图片压缩完毕，成功率：%.2f%%", progress)
        print("\(log)")
    }
    
    private func upload(file: String, with key: String, progress: Double) {
        let progressString = String.init(format: "进度：%.2f%%", progress)
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
                    print("\(file) 上传失败 \(progressString)\n", terminator: "")
                    self.failedFiles.append(file)
                    self.semaphore.signal()
                    return
                }
                
                let requestCompress = NSMutableURLRequest(url: url)
                requestCompress.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                requestCompress.setValue(key, forHTTPHeaderField: "Authorization")
                let taskCompress = URLSession.shared.dataTask(with: requestCompress as URLRequest, completionHandler: { (data, respinse, error) in
                    
                    defer {
                        self.semaphore.signal()
                    }
                    
                    guard error == nil else {
                        print("\(file) 压缩失败 \(progressString)\n", terminator: "")
                        self.failedFiles.append(file)
                        return
                    }
                    
                    try? data?.write(to: fileUrl, options: .atomic)
                    print("\(file) 压缩成功 \(progressString)\n", terminator: "")
                })
                taskCompress.resume()
                
            } else {
                self.failedFiles.append(file)
                print("上传失败可能超过限制，切换Api Key \(progressString)\n", terminator: "")
                self.keyIndex += 1
                self.semaphore.signal()
            }
        })
        task.resume()
    }
}
