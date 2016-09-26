//
//  BookmarkRoot.swift
//  Xjournal
//
//  Created by C.W. Betts on 6/1/15.
//
//

import Foundation

class BookmarkRoot: CustomStringConvertible {
	var title: String
	
	init(title newTitle: String) {
		title = newTitle
	}
	
	func compare(other: BookmarkRoot) -> ComparisonResult {
		return title.compare(other.title)
	}
	
	var hasChildren: Bool {
		return false
	}
	
	var description: String {
		return "Bookmark Root"
	}
}
