//
//  HELogger.swift
//  HECommon
//
//  Created by hyonsoo on 8/15/24.
//

import Foundation
import os

open class _HELoggerBase {
    public let tag: String
    public let category: String
    public let logger: Logger
    
    public init(category: String, tag: String) {
        self.category = category
        self.tag = tag
        self.logger = Logger(subsystem: "hiclass", category: category)
    }
    
    open func trace(filename: String = #file, line: Int = #line, funcName: String = #function) {}
    open func trace<T>(_ object: T?, filename: String = #file, line: Int = #line, funcName: String = #function) {}
    open func woops<T>(_ object: T?, filename: String = #file, line: Int = #line, funcName: String = #function) {}
}

open class HELogger: _HELoggerBase {
    
#if DEBUG
    fileprivate var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss"
        return formatter
    }()
    
    open override func trace(filename: String = #file, line: Int = #line, funcName: String = #function) {
        let th = Thread.current.isMainThread ? "[main]": "[\(Thread.current.name ?? "-")]"
        let time = timeFormatter.string(from: Date())
        let file = filename.components(separatedBy: "/").last?.split(separator: ".").first ?? ""
        let leading = "\(tag) \(time) \(th) \(file) (L\(line))::\(funcName)"
        //print("\(leading) nil")
        logger.log("\(leading, privacy: .public)")
    }
    
    open override func trace<T>(_ object: T?, filename: String = #file, line: Int = #line, funcName: String = #function) {
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
    
    open override func woops<T>(_ object: T?, filename: String = #file, line: Int = #line, funcName: String = #function) {
        let th = Thread.current.isMainThread ? "[main]": "[\(Thread.current.name ?? "-")]"
        let time = timeFormatter.string(from: Date())
        let file = filename.components(separatedBy: "/").last?.split(separator: ".").first ?? ""
        let leading = "\(tag) 💥 \(time) \(th) \(file) (L\(line))::\(funcName)"
        if let obj = object {
            // print("\(leading) \(obj)")
            logger.error("\(leading, privacy: .public) \(String(describing: obj), privacy: .public)")
        } else {
            //print("\(leading) nil")
            logger.error("\(leading, privacy: .public)  nil")
        }
    }
#endif
    
}
