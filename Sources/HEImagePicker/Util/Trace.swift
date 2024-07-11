//
//  Trace.swift
//  HEImagePicker
//
//  Created by 브라운수 on 7/2/24.
//

import Foundation

#if DEBUG
import os

fileprivate let tag = "*HEPicker*"

fileprivate var logger: Logger = {
    return Logger(subsystem: "hi", category: "image-editor")
}()

fileprivate var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm:ss"
    return formatter
}()

func trace(filename: String = #file, line: Int = #line, funcName: String = #function) {
    let th = Thread.current.isMainThread ? "[main]": "[\(Thread.current.name ?? "-")]"
    let time = timeFormatter.string(from: Date())
    let file = filename.components(separatedBy: "/").last?.split(separator: ".").first ?? ""
    let leading = "\(tag) \(time) \(th) \(file) (L\(line))::\(funcName)"
    //print("\(leading) nil")
    logger.log("\(leading, privacy: .public)")
}

func trace<T>(_ object: T?, filename: String = #file, line: Int = #line, funcName: String = #function) {
    let th = Thread.current.isMainThread ? "[main]": "[\(Thread.current.name ?? "-")]"
    let time = timeFormatter.string(from: Date())
    let file = filename.components(separatedBy: "/").last?.split(separator: ".").first ?? ""
    let leading = "\(tag) \(time) \(th) \(file) (L\(line))::\(funcName)"
    if let obj = object {
       // print("\(leading) \(obj)")
        logger.log("\(leading, privacy: .public) \(String(describing: obj), privacy: .public)")
    } else {
        //print("\(leading) nil")
        logger.log("\(leading, privacy: .public)  nil")
    }
}

func woops<T>(_ object: T?, filename: String = #file, line: Int = #line, funcName: String = #function) {
    let th = Thread.current.isMainThread ? "[main]": "[\(Thread.current.name ?? "-")]"
    let time = timeFormatter.string(from: Date())
    let file = filename.components(separatedBy: "/").last?.split(separator: ".").first ?? ""
    let leading = "\(tag) 💥 \(time) \(th) \(file) (L\(line))::\(funcName)"
    if let obj = object {
       // print("\(leading) \(obj)")
        logger.log("\(leading, privacy: .public) \(String(describing: obj), privacy: .public)")
    } else {
        //print("\(leading) nil")
        logger.log("\(leading, privacy: .public)  nil")
    }
}

#else
func trace() {}
func trace<T>(_ object: T?) {
    // 제외
}
func woops<T>(_ object: T?) {
    // 제외
}
#endif
