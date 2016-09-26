//
//  XJUserNotification.swift
//  Xjournal
//
//  Created by C.W. Betts on 1/25/15.
//
//

import Cocoa

class XJUserNotification: NSObject, NSUserNotificationCenterDelegate {
    let notification = NSUserNotificationCenter.default
    
    override init() {
        super.init()
        notification.delegate = self
    }
    
    func showNotification(_ name: String, callback: (() -> Void)?) {
        
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        let defaults = UserDefaults.standard
        let always = defaults.bool(forKey: XJNotificationShowAlways)
        
        return always
    }
}
