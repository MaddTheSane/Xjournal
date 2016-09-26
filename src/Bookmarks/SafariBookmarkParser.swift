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
    let fm = FileManager.default
    let globalAppURL = try! fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    return globalAppURL.path
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
		var safariArray = (localLibraryDir() as NSString).pathComponents
		safariArray.append(contentsOf: ["Safari", "Bookmarks.plist"])
		let path = NSURL.fileURL(withPathComponents: safariArray)! as URL
		let bookmarks = NSDictionary(contentsOf: path)!
		rootFolder = BookmarkFolder(title: "__root_item__")
		parseAddressBook(into: rootFolder!)
		parse(dict: bookmarks, withRootFolder: rootFolder!)
	}
	
	/// Take a dictionary and parse it for bookmarks.  This is a (sort-of) recursive method
	/// since bookmark folders can be arbitrarily nested (AFAIK).
	private func parse(dict: NSDictionary, withRootFolder root: BookmarkFolder) {
		if let type = dict["WebBookmarkType"] as? String, type == "WebBookmarkTypeList" {
			// If it's a list is has a key "Children" which is an array of Leaf dictionaries
			if let kids = dict["Children"] as? [NSDictionary] {
				
				for child in kids {
					if (child["WebBookmarkType"] as? String) == "WebBookmarkTypeList" {
						parse(list: child, withRootFolder: root) // Parse a list
					} else {
						parse(leaf: child, withRootFolder: root) // Parse one item
					}
				}
			}
		}
	}
	
	/// This method parses what we know is a folder of bookmarks into
	/// an XJBookmarkFolder structure
	private func parse(list dict: NSDictionary, withRootFolder root: BookmarkFolder) {
		if let folderTitle = dict["Title"] as? String {
			let thisFolder = BookmarkFolder(title: folderTitle)
			
			// If it's a list is has a key "Children" which is an array of Leaf dictionaries
			let kids = dict["Children"] as! [NSDictionary]
			for child in kids {
				if (child["WebBookmarkType"] as? String) == "WebBookmarkTypeList" {
					parse(list: child, withRootFolder: thisFolder)
				} else {
					parse(leaf: child, withRootFolder: thisFolder)
				}
			}
			
			root.add(child: thisFolder)
		}
	}
	
	/// Parses a leaf NSDictionary into an XJBookmarkItem structure and attaches
	/// it to the given root.
	private func parse(leaf: NSDictionary, withRootFolder root: BookmarkFolder) {
		if let uriDict = leaf["URIDictionary"] as? NSDictionary, let title = uriDict["title"] as? String, let url = leaf["URLString"] as? String {
			let child = BookmarkItem(title: title, address: URL(string: url)!)
			root.add(child: child)
		}
	}
	
	/// Reads all the URLs from Address Book and makes them children
	/// of the given `BookmarkFolder`.
	private func parseAddressBook(into root: BookmarkFolder) {
		let book = ABAddressBook.shared()!
		let abFolder = BookmarkFolder(title: NSLocalizedString("Address Book", comment: ""))
		let everyone = book.people()!
		var dictionary = [String: ABMultiValue]()
		
		for person in everyone {
			if let person = person as? ABPerson, let data = person.value(forProperty: kABURLsProperty) as? ABMultiValue {
				/*
				* i.e. if the Person record has a home page property,
				* we then figure out what name to give this bookmark -
				* whether a person's name or a business.
				*/
				let fname = (person.value(forProperty: kABFirstNameProperty) as? String) ?? ""
				let lname = (person.value(forProperty: kABLastNameProperty) as? String) ?? ""
				
				if (fname.characters.count == 0) && (lname.characters.count == 0) {
					// Neither first nor last name, so likely a company business card
					if let cname = person.value(forProperty: kABOrganizationProperty) as? String {
						dictionary[cname] = data
					}
				} else {
					dictionary["\(fname) \(lname)"] = data
				}
			}
		}
		
		// Now, take all the Name/URL key-values and make then into XJBookmarkItems
		var allDictKeys = Array(dictionary.keys)
		allDictKeys.sort(by: <)
		for key in allDictKeys {
			let person = dictionary[key]!
			let urls: [String] = {
				var urls = [String]()
				for i in 0..<person.count() {
					if let idxStr = person.value(at: i) as? String {
						urls.append(idxStr)
					}
				}
				
				return urls
			}()
			//println("\(key) \(person), \(urls)")
			let newChild = BookmarkItem(title: key, address: URL(string: urls.first!)!)
			abFolder.add(child: newChild)
		}
		
		root.add(child: abFolder)
	}
	
	// MARK: OutlineView Data Source
	
	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		if item == nil {
			return rootFolder!.child(at: index)
		} else {
			let item = item as! BookmarkFolder
			return item.child(at: index)
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		let item: AnyObject? = item as AnyObject?
		
		if let item = item as? BookmarkRoot {
			return item.hasChildren
		} else {
			return false
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		if let item = item as? BookmarkFolder {
			return item.numberOfChildren
		} else {
			return rootFolder?.numberOfChildren ?? 0
		}
	}
	
	func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
		if let tableID = tableColumn?.identifier, let item = item as? BookmarkRoot {
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
	
	func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
		var dragString = ""
		
		//pasteboard.declareTypes([NSPasteboardTypeString], owner: self)
		pasteboard.clearContents()
		let optKeyDown = NSApplication.shared().currentEvent!.modifierFlags.contains(.option)
		
		if let items = items as? [BookmarkItem] {
			var urls = [URL]()
			for item in items {
				urls.append(item.webAddress)
				if !optKeyDown {
					dragString += " \(item.webAddress.description)"
				} else {
					dragString += " <a href=\"\(item.webAddress.description)\">\(item.title)</a>"
				}
			}
			var toWrite: [NSPasteboardWriting] = [dragString as NSString]
			toWrite += urls as [NSPasteboardWriting]
			return pasteboard.writeObjects(toWrite)
		}
		
		return false
	}
}
