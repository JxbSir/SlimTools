//
//  main.swift
//  SlimTools
//
//  Created by Peter Jin on 2018/8/9.
//  Copyright © 2018 Jxb. All rights reserved.
//

import Foundation

enum Mode: String {
    case md5  = "1"
    case tiny = "2"
}

var mode: Mode?

repeat {
    print("请选择模式:\n1:查找重复资源文件\n2:使用Tinypng进行压缩\nq:退出")
    
    if let m = readLine()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
        if let _m = Mode(rawValue: m) {
            mode = _m
        } else if m == "q" {
            exit(0)
        }
    }
} while (mode == nil)

print("请选择模式输入工程目录地址:")

if let m = mode, let dir = readLine()?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {

    switch m {
    case .md5:
        let md5 = MD5()
        md5.start(dir: dir)
        
    case .tiny:
        let tinypng = Tinypng()
        tinypng.start(dir: dir)
        
    }
}


