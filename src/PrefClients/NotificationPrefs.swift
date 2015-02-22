//
//  NotificationPrefs.swift
//  Xjournal
//
//  Created by C.W. Betts on 2/22/15.
//
//

import Cocoa

class NotificationPrefs: NSView {

	@IBOutlet weak var showNotifications: NSButton!
	@IBOutlet weak var showOnFriends: NSButton!
	@IBOutlet weak var showInForeground: NSButton!
	@IBAction func toggleNotifications(sender: AnyObject!) {
		let active = showNotifications.state == NSOnState
		
		showOnFriends.enabled = active
		showInForeground.enabled = active
	}
    
    override func awakeFromNib() {
        toggleNotifications(nil)
    }
}
