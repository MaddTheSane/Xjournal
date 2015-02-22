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
    
    func showNotification(name: String, callback: dispatch_block_t?) {
        
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let always = defaults.boolForKey(XJNotificationShowAlways)
        
        return always
    }
}
