//
//  BookmarkItem.swift
//  Xjournal
//
//  Created by C.W. Betts on 6/1/15.
//
//

import Foundation

final class BookmarkItem: BookmarkRoot {
	var webAddress: NSURL
	
	init(title newTitle: String, address: NSURL) {
		webAddress = address
		super.init(title: newTitle)
	}
	
	override convenience init(title newTitle: String) {
		self.init(title: newTitle, address: NSURL(string: "http://www.google.com")!)
	}
	
	override var description: String {
		return "XJBookmarkItem: \(title) (\(webAddress.description))"
	}
}
