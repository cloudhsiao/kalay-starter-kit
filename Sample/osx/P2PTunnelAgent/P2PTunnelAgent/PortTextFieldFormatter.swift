//
//  PortTextFieldFormatter.swift
//  P2PTunnelAgent
//
//  Created by Cloud Hsiao on 9/16/15.
//  Copyright (c) 2015 ThroughTek. All rights reserved.
//

import Foundation
import Cocoa

class PortTextFieldFormatter: NSFormatter {
    override func stringForObjectValue(obj: AnyObject?) -> String? {
        if obj == nil {
            return nil
        }
        if let o = obj as? String {
            return o
        }
        return nil
    }
    
    override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>, forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        obj.memory = string
        return true
    }
    
    override func isPartialStringValid(partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString?>, proposedSelectedRange proposedSelRangePtr: NSRangePointer, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        if let s = partialStringPtr.memory {
            if s.length == 0 {
                return true
            }
            let scanner = NSScanner(string: s as String)
            return scanner.scanDecimal(nil) && scanner.atEnd
            
        }
        return true
    }
}