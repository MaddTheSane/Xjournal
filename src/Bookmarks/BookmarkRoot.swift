//
//  BookmarkRoot.swift
//  Xjournal
//
//  Created by C.W. Betts on 6/1/15.
//
//

import Foundation



class BookmarkRoot: NSObject {
	var title: String
	
	init(title newTitle: String) {
		title = newTitle
		super.init()
	}
	
	func compare(other: BookmarkRoot) -> NSComparisonResult {
		return title.compare(other.title)
	}
	
	var hasChildren: Bool {
		return false
	}
}
