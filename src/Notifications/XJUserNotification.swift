//
//  XJUserNotification.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/25/15.
//
//

import Cocoa

class XJUserNotification: NSObject, NSUserNotificationCenterDelegate {
    let notification = NSUserNotificationCenter.defaultUserNotificationCenter()
    
    override init() {
        super.init()
        notification.delegate = self
    }
}
