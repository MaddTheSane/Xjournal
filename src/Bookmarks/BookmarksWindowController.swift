//
//  BookmarksWindowController.swift
//  Xjournal
//
//  Created by C.W. Betts on 6/16/15.
//
//

import Cocoa

private let kBookmarkWindowToolbarIdentifier = "BookmarkWindowToolbarIdentifier"
private let kBookmarkRefreshItemIdentifier = "BookmarkRefreshItemIdentifier"
private let kBookmarkExpandAllItemIdentifier = "BookmarkExpandAllItemIdentifier"
private let kBookmarkCollapseAllItemIdentifier = "BookmarkCollapseAllItemIdentifier"

class BookmarksWindowController: NSWindowController {
    //    IBOutlet NSOutlineView* outline;
    @IBOutlet weak var outline: NSOutlineView!
    fileprivate var toolbarItemCache = [String: NSToolbarItem]()
    fileprivate let parser = SafariBookmarkParser()
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		outline.register(forDraggedTypes: [NSStringPboardType])
		outline.autosaveTableColumns = true
		// Set up NSToolbar
		let toolbar = NSToolbar(identifier: kBookmarkWindowToolbarIdentifier)
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
		toolbar.delegate = self
		window?.toolbar = toolbar
		
		refreshBookmarks(self)
    }
	
	/// Refresh the bookmarks from disk.
	@IBAction func refreshBookmarks(_ sender: AnyObject?) {
		parser.refreshFromDisk()
		outline.reloadData()
	}
	
	@IBAction func expandAll(_ sender: AnyObject?) {
		let root = parser.rootItem as! BookmarkFolder
		for i in 0..<root.numberOfChildren {
			outline.expandItem(root.child(at: i), expandChildren: true)
		}
	}
	
	@IBAction func collapseAll(_ sender: AnyObject?) {
		let root = parser.rootItem as! BookmarkFolder
		for i in 0..<root.numberOfChildren {
			outline.collapseItem(root.child(at: i), collapseChildren: true)
		}
	}
}

private let STRIPE_RED =	CGFloat(237.0 / 255.0)
private let STRIPE_GREEN =	CGFloat(243.0 / 255.0)
private let STRIPE_BLUE =	CGFloat(254.0 / 255.0)

/// OutlineView Data Source - forwards most calls to the bookmark parser object.
extension BookmarksWindowController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		return parser.outlineView(outlineView, child: index, ofItem: item)
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return parser.outlineView(outlineView, isItemExpandable: item)
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		return parser.outlineView(outlineView, numberOfChildrenOfItem: item)
	}
	
	func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
		return parser.outlineView(outlineView, objectValueFor: tableColumn, byItem: item)
	}
	
	func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
		return parser.outlineView(outlineView, writeItems: items, to: pasteboard)
	}
	
	func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
		return false
	}
	
	func outlineView(_ outlineView: NSOutlineView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
		if tableColumn?.identifier != "title" {
			if let _ = item as? BookmarkFolder {
				(cell as! NSTextFieldCell).textColor = NSColor.gray
			} else {
				(cell as! NSTextFieldCell).textColor = NSColor.black
			}
		}
	}
}

extension BookmarksWindowController: NSToolbarDelegate {
	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		var item: NSToolbarItem? = toolbarItemCache[itemIdentifier]
		
		if item == nil {
			let tmpItem = NSToolbarItem(itemIdentifier: itemIdentifier);
			item = tmpItem
			tmpItem.image = NSImage(named: "Placeholder")
			
			switch itemIdentifier {
			case kBookmarkRefreshItemIdentifier:
				tmpItem.label = NSLocalizedString("Refresh", comment: "")
				tmpItem.paletteLabel = NSLocalizedString("Refresh", comment: "")
				tmpItem.target = self
				tmpItem.action = #selector(BookmarksWindowController.refreshBookmarks(_:))
				tmpItem.toolTip = NSLocalizedString("Refresh bookmarks", comment: "")
				tmpItem.image = NSImage(named: "Refresh")
				
			case kBookmarkCollapseAllItemIdentifier:
				tmpItem.label = NSLocalizedString("Collapse All", comment: "")
				tmpItem.paletteLabel = NSLocalizedString("Collapse All", comment: "")
				tmpItem.target = self
				tmpItem.action = #selector(BookmarksWindowController.collapseAll(_:))
				tmpItem.toolTip = NSLocalizedString("Collapse all bookmarks", comment: "")
				tmpItem.image = NSImage(named: "CollapseAll")
				
			case kBookmarkExpandAllItemIdentifier:
				tmpItem.label = NSLocalizedString("Expand All", comment: "")
				tmpItem.paletteLabel = NSLocalizedString("Expand All", comment: "")
				tmpItem.target = self
				tmpItem.action = #selector(BookmarksWindowController.expandAll(_:))
				tmpItem.toolTip = NSLocalizedString("Expand all bookmarks", comment: "")
				tmpItem.image = NSImage(named: "ExpandAll")
				
			default:
				item = nil
			}
			
			if let item = item {
				toolbarItemCache[itemIdentifier] = item;
			}
		}
		
		return item
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
		return [kBookmarkRefreshItemIdentifier,
		kBookmarkExpandAllItemIdentifier,
		kBookmarkCollapseAllItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier]
	}
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
		return [kBookmarkExpandAllItemIdentifier, kBookmarkCollapseAllItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, kBookmarkRefreshItemIdentifier]
	}
}
