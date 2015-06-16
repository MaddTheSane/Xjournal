//
//  BookmarkFolder.swift
//  Xjournal
//
//  Created by C.W. Betts on 6/1/15.
//
//

import Cocoa

final class BookmarkFolder: BookmarkRoot {
	private var children = [BookmarkRoot]()
	
	override init(title newTitle: String) {
		children.reserveCapacity(20)
		super.init(title: newTitle)
	}
	
	override var hasChildren: Bool {
		return children.count > 0
	}
	
	var numberOfChildren: Int {
		return children.count
	}
	
	func childAtIndex(idx: Int) -> BookmarkRoot {
		return children[idx]
	}
	
	func addChild(child: BookmarkRoot) {
		children.append(child)
	}
	
	override var description: String {
		return "XJBookmarkFolder: \(title) (\(numberOfChildren))"
	}
}
