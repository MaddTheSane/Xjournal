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
    private var toolbarItemCache = [String: NSToolbarItem]()
    private let parser = SafariBookmarkParser()
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		outline.registerForDraggedTypes([NSStringPboardType])
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
	@IBAction func refreshBookmarks(sender: AnyObject?) {
		parser.refreshFromDisk()
		outline.reloadData()
	}
	
	@IBAction func expandAll(sender: AnyObject?) {
		let root = parser.rootItem as! BookmarkFolder
		for i in 0..<root.numberOfChildren {
			outline.expandItem(root.childAtIndex(i), expandChildren: true)
		}
	}
	
	@IBAction func collapseAll(sender: AnyObject?) {
		let root = parser.rootItem as! BookmarkFolder
		for i in 0..<root.numberOfChildren {
			outline.collapseItem(root.childAtIndex(i), collapseChildren: true)
		}
	}
}

let STRIPE_RED =	CGFloat(237.0 / 255.0)
let STRIPE_GREEN =	CGFloat(243.0 / 255.0)
let STRIPE_BLUE =	CGFloat(254.0 / 255.0)

/// OutlineView Data Source - forwards most calls to the bookmark parser object.
extension BookmarksWindowController: NSOutlineViewDataSource, NSOutlineViewDelegate {
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		return parser.outlineView(outlineView, child: index, ofItem: item)
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		return parser.outlineView(outlineView, isItemExpandable: item)
	}
	
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		return parser.outlineView(outlineView, numberOfChildrenOfItem: item)
	}
	
	func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
		return parser.outlineView(outlineView, objectValueForTableColumn: tableColumn, byItem: item)
	}
	
	func outlineView(outlineView: NSOutlineView, writeItems items: [AnyObject], toPasteboard pasteboard: NSPasteboard) -> Bool {
		return parser.outlineView(outlineView, writeItems: items, toPasteboard: pasteboard)
	}
	
	func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
		return false
	}
	
	func outlineView(outlineView: NSOutlineView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, item: AnyObject) {
		if tableColumn?.identifier != "title" {
			if let _ = item as? BookmarkFolder {
				(cell as! NSTextFieldCell).textColor = NSColor.grayColor()
			} else {
				(cell as! NSTextFieldCell).textColor = NSColor.blackColor()
			}
		}
	}
}

extension BookmarksWindowController: NSToolbarDelegate {
	func toolbar(toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
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
				tmpItem.action = "refreshBookmarks:"
				tmpItem.toolTip = NSLocalizedString("Refresh bookmarks", comment: "")
				tmpItem.image = NSImage(named: "Refresh")
				
			case kBookmarkCollapseAllItemIdentifier:
				tmpItem.label = NSLocalizedString("Collapse All", comment: "")
				tmpItem.paletteLabel = NSLocalizedString("Collapse All", comment: "")
				tmpItem.target = self
				tmpItem.action = "collapseAll:"
				tmpItem.toolTip = NSLocalizedString("Collapse all bookmarks", comment: "")
				tmpItem.image = NSImage(named: "CollapseAll")
				
			case kBookmarkExpandAllItemIdentifier:
				tmpItem.label = NSLocalizedString("Expand All", comment: "")
				tmpItem.paletteLabel = NSLocalizedString("Expand All", comment: "")
				tmpItem.target = self
				tmpItem.action = "expandAll:"
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
	
	func toolbarAllowedItemIdentifiers(toolbar: NSToolbar) -> [String] {
		return [kBookmarkRefreshItemIdentifier,
		kBookmarkExpandAllItemIdentifier,
		kBookmarkCollapseAllItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier]
	}
	
	func toolbarDefaultItemIdentifiers(toolbar: NSToolbar) -> [String] {
		return [kBookmarkExpandAllItemIdentifier, kBookmarkCollapseAllItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, kBookmarkRefreshItemIdentifier]
	}
}
