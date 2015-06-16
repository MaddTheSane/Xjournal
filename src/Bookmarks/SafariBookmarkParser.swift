//
//  SafariBookmarkParser.swift
//  Xjournal
//
//  Created by C.W. Betts on 6/1/15.
//
//

import Cocoa
import AddressBook

private func localLibraryDir() -> String {
    let fm = NSFileManager.defaultManager()
    let globalAppURL = try! fm.URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
    return globalAppURL.path!
}

final class SafariBookmarkParser: NSObject, NSOutlineViewDataSource {
	private var rootFolder: BookmarkFolder?
	
	/// Returns the root of the bookmark tree.
	var rootItem: AnyObject {
		return rootFolder!
	}
	
	/// Refresh the bookmarks from the Safari plist.
	func refreshFromDisk() {
		//TODO: update? Perhaps use Spotlight?
		var safariArray = localLibraryDir().pathComponents
		safariArray.extend(["Safari", "Bookmarks.plist"])
		let path = String.pathWithComponents(safariArray)
		let bookmarks = NSDictionary(contentsOfFile: path)!
		rootFolder = BookmarkFolder(title: "__root_item__")
		parseAddressBookIntoFolder(rootFolder!)
		parseDict(bookmarks, withRootFolder: rootFolder!)
	}
	
	/// Take a dictionary and parse it for bookmarks.  This is a (sort-of) recursive method
	/// since bookmark folders can be arbitrarily nested (AFAIK).
	private func parseDict(dict: NSDictionary, withRootFolder root: BookmarkFolder) {
		if let type = dict["WebBookmarkType"] as? String where type == "WebBookmarkTypeList" {
			// If it's a list is has a key "Children" which is an array of Leaf dictionaries
			if let kids = dict["Children"] as? [NSDictionary] {
				
				for child in kids {
					if (child["WebBookmarkType"] as? String) == "WebBookmarkTypeList" {
						parseList(child, withRootFolder: root) // Parse a list
					} else {
						parseLeaf(child, withRootFolder: root) // Parse one item
					}
				}
			}
		}
	}
	
	/// This method parses what we know is a folder of bookmarks into
	/// an XJBookmarkFolder structure
	private func parseList(dict: NSDictionary, withRootFolder root: BookmarkFolder) {
		if let folderTitle = dict["Title"] as? String {
			let thisFolder = BookmarkFolder(title: folderTitle)
			
			// If it's a list is has a key "Children" which is an array of Leaf dictionaries
			let kids = dict["Children"] as! [NSDictionary]
			for child in kids {
				if (child["WebBookmarkType"] as? String) == "WebBookmarkTypeList" {
					parseList(child, withRootFolder: thisFolder)
				} else {
					parseLeaf(child, withRootFolder: thisFolder)
				}
			}
			
			root.addChild(thisFolder)
		}
	}
	
	/// Parses a leaf NSDictionary into an XJBookmarkItem structure and attaches
	/// it to the given root.
	private func parseLeaf(leaf: NSDictionary, withRootFolder root: BookmarkFolder) {
		if let uriDict = leaf["URIDictionary"] as? NSDictionary, title = uriDict["title"] as? String, url = leaf["URLString"] as? String {
			let child = BookmarkItem(title: title, address: NSURL(string: url)!)
			root.addChild(child)
		}
	}
	
	/// Reads all the URLs from Address Book and makes them children
	/// of the given `BookmarkFolder`.
	private func parseAddressBookIntoFolder(root: BookmarkFolder) {
		let book = ABAddressBook.sharedAddressBook()!
		let abFolder = BookmarkFolder(title: NSLocalizedString("Address Book", comment: ""))
		let everyone = book.people()!
		var dictionary = [String: ABMultiValue]()
		
		for person in everyone {
			if let person = person as? ABPerson, data = person.valueForProperty(kABURLsProperty) as? ABMultiValue {
				/*
				* i.e. if the Person record has a home page property,
				* we then figure out what name to give this bookmark -
				* whether a person's name or a business.
				*/
				let fname = (person.valueForProperty(kABFirstNameProperty) as? String) ?? ""
				let lname = (person.valueForProperty(kABLastNameProperty) as? String) ?? ""
				
				if (fname.characters.count == 0) && (lname.characters.count == 0) {
					// Neither first nor last name, so likely a company business card
					if let cname = person.valueForProperty(kABOrganizationProperty) as? String {
						dictionary[cname] = data
					}
				} else {
					dictionary["\(fname) \(lname)"] = data
				}
			}
		}
		
		// Now, take all the Name/URL key-values and make then into XJBookmarkItems
		var allDictKeys = dictionary.keys.array
		allDictKeys.sortInPlace(<)
		for key in allDictKeys {
			let person = dictionary[key]!
			let urls: [String] = {
				var urls = [String]()
				for i in 0..<person.count() {
					if let idxStr = person.valueAtIndex(i) as? String {
						urls.append(idxStr)
					}
				}
				
				return urls
			}()
			//println("\(key) \(person), \(urls)")
			let newChild = BookmarkItem(title: key, address: NSURL(string: urls.first!)!)
			abFolder.addChild(newChild)
		}
		
		root.addChild(abFolder)
	}
	
	// MARK: OutlineView Data Source
	
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if item == nil {
			return rootFolder!.childAtIndex(index)
		} else {
			let item = item as! BookmarkFolder
			return item.childAtIndex(index)
		}
	}
	
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		let item: AnyObject? = item as AnyObject?
		
		if let item = item as? BookmarkRoot {
			return item.hasChildren
		} else {
			return true
		}
	}
	
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if let item = item as? BookmarkFolder {
			return item.numberOfChildren
		} else {
			return rootFolder!.numberOfChildren
		}
	}
	
	func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
		if let tableID = tableColumn?.identifier, item = item as? BookmarkRoot {
			if tableID == "title" {
				return item.title
			} else {
				if let item = item as? BookmarkItem {
					return item.webAddress.description
				} else if let item = item as? BookmarkFolder {
					return "\(item.numberOfChildren) items"
				}
			}
		}
		
		return ""
	}
	
	func outlineView(outlineView: NSOutlineView, writeItems items: [AnyObject], toPasteboard pasteboard: NSPasteboard) -> Bool {
		var dragString = ""
		
		//pasteboard.declareTypes([NSPasteboardTypeString], owner: self)
		pasteboard.clearContents()
		let optKeyDown = NSApplication.sharedApplication().currentEvent!.modifierFlags.contains(.AlternateKeyMask)
		
		if let items = items as? [BookmarkItem] {
			var urls = [NSURL]()
			for item in items {
				urls.append(item.webAddress)
				if !optKeyDown {
					dragString += " \(item.webAddress.description)"
				} else {
					dragString += " <a href=\"\(item.webAddress.description)\">\(item.title)</a>"
				}
			}
			var toWrite: [NSPasteboardWriting] = [dragString]
			toWrite += urls as [NSPasteboardWriting]
			return pasteboard.writeObjects(toWrite)
		}
		
		return false
	}
}
