//
//  XJSafariBookmarkParser.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed Jan 29 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJSafariBookmarkParser.h"
#import <AddressBook/AddressBook.h>

@interface XJSafariBookmarkParser (PrivateAPI)
- (void)parseAddressBookIntoFolder: (XJBookmarkFolder *)root;
- (void)parseDict:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root;
- (void)parseList:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root;
- (void)parseLeaf:(NSDictionary *)leaf withRootFolder: (XJBookmarkFolder *)root;
@end

@implementation XJSafariBookmarkParser
- (id)init {
    if(self == [super init]) {
        return self;
    }
    return nil;
}

/*
 * Refresh the bookmarks from the Safari plist.
 */
- (void)refreshFromDisk
{
    NSString *path = [@"~/Library/Safari/Bookmarks.plist" stringByExpandingTildeInPath];
    NSDictionary *bookmarks = [NSDictionary dictionaryWithContentsOfFile: path];
    if(rootFolder) {
        [rootFolder release];
    }
    rootFolder = [[XJBookmarkFolder folderWithTitle: @"__root_item__"] retain];
    [self parseAddressBookIntoFolder: rootFolder];
    [self parseDict: bookmarks withRootFolder: rootFolder];
}

/*
 * Returns the root of the bookmark tree.
 */
- (id)rootItem
{
    return rootFolder;
}
@end

@implementation XJSafariBookmarkParser (PrivateAPI)
/*
 * Reads all the URLs from Address Book and makes them children
 * of the given XJBookmarkFolder
 */
- (void)parseAddressBookIntoFolder: (XJBookmarkFolder *)root
{
    NSArray *everyone;
    NSEnumerator *enumerator;
    id key;
    ABPerson *person;
    int i;
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    XJBookmarkFolder *abFolder = [XJBookmarkFolder folderWithTitle: NSLocalizedString(@"Address Book", @"")];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    everyone = [book people];

    for(i=0; i < [everyone count]; i++) {
        NSString *data, *fname, *lname, *cname = nil;
        person = [everyone objectAtIndex: i];

        data = [person valueForProperty: kABHomePageProperty];
        
        if(data) {
            /*
             * i.e. if the Person record has a home page property,
             * we then figure out what name to give this bookmark -
             * whether a person's name or a business.
             */
            fname = [person valueForProperty: kABFirstNameProperty];
            if(!fname)
                fname = @"";

            lname = [person valueForProperty: kABLastNameProperty];
            if(!lname)
                lname = @"";

            if(([fname length] == 0) && ([lname length] == 0)) {
                // Neither first nor last name, so likely a company business card
                cname = [person valueForProperty: kABOrganizationProperty];
                if(cname) {
                    [dictionary setObject: data forKey: cname];
                }
            }
            else {
                [dictionary setObject: data forKey: [NSString stringWithFormat: @"%@ %@", fname, lname]];
            }
        }
    }

    // Now, take all the Name/URL key-values and make then into XJBookmarkItems
    enumerator = [[[dictionary allKeys] sortedArrayUsingSelector: @selector(compare:)] objectEnumerator];
    while(key = [enumerator nextObject]) {
        [abFolder addChild: [XJBookmarkItem bookmarkWithTitle: key address: [NSURL URLWithString: [dictionary objectForKey: key]]]];
    }
            
    [root addChild: abFolder];
}

/*
 * Take a dictionary and parse it for bookmarks.  This is a (sort-of) recursive method
 * since bookmark folders can be arbitrarily nested (AFAIK)
 */
- (void)parseDict:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root
{
    NSString *type = [dict objectForKey: @"WebBookmarkType"];

    if([type isEqualToString: @"WebBookmarkTypeList"]) {
        // If it's a list is has a key "Children" which is an array of Leaf dictionaries
        NSArray *kids = [dict objectForKey: @"Children"];
        NSEnumerator *enumer = [kids objectEnumerator];
        NSDictionary *child;

        while(child = [enumer nextObject]) {
            if([[child objectForKey: @"WebBookmarkType"] isEqualToString: @"WebBookmarkTypeList"])
                [self parseList: child withRootFolder: root]; // Parse a list
            else
                [self parseLeaf: child withRootFolder: root]; // Parse one item
        }
    }        
}

/*
 * This method parses what we know is a folder of bookmarks into 
 * an XJBookmarkFolder structure
 */
- (void)parseList:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root
{
    XJBookmarkFolder *thisFolder;
    NSString *folderTitle = [dict objectForKey: @"Title"];
    thisFolder = [[XJBookmarkFolder folderWithTitle: folderTitle] retain];

    // If it's a list is has a key "Children" which is an array of Leaf dictionaries
    NSArray *kids = [dict objectForKey: @"Children"];
    NSEnumerator *enumer = [kids objectEnumerator];
    NSDictionary *child;

    while(child = [enumer nextObject]) {
        if([[child objectForKey: @"WebBookmarkType"] isEqualToString: @"WebBookmarkTypeList"])
            [self parseList: child withRootFolder: thisFolder];
        else
            [self parseLeaf: child withRootFolder: thisFolder];
    }

    [root addChild: thisFolder];
}

/*
 * Parses a leaf NSDictionary into an XJBookmarkItem structure and attaches
 * it to the given root.
 */
- (void)parseLeaf:(NSDictionary *)leaf withRootFolder: (XJBookmarkFolder *)root
{
    NSDictionary *uriDict = [leaf objectForKey: @"URIDictionary"];
    NSString *title = [uriDict objectForKey: @"title"], *url = [leaf objectForKey: @"URLString"];

    if(title != nil & url!= nil) {
        [root addChild: [XJBookmarkItem bookmarkWithTitle: title address: [NSURL URLWithString: url]]];
    }
}

// ----------------------------------------------------------------------------------------
// OutlineView Data Source
// ----------------------------------------------------------------------------------------
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil)
        return [rootFolder childAtIndex: index];
    else {
        return [item childAtIndex: index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{ 
    if(item == nil)
        return YES;
    else {
        return [item hasChildren];
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil) {
        return [rootFolder numberOfChildren];
    }
    else {
        return [item numberOfChildren];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([[tableColumn identifier] isEqualToString: @"title"]) {
        return [item title];
    } else {
        if([item isKindOfClass: [XJBookmarkItem class]])
            return [[item webAddress] description];
        
        else if([item isKindOfClass: [XJBookmarkFolder class]])
            return [NSString stringWithFormat: @"%u items", [item numberOfChildren]];
    }
    return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pb
{
    NSEnumerator *enumer = [items objectEnumerator];
    id item;
    NSString *dragString = @"";

    [pb declareTypes:[NSArray arrayWithObjects: NSStringPboardType, nil] owner:self];
    
    while(item = [enumer nextObject]) {
        BOOL optKeyDown = ([[NSApp currentEvent] modifierFlags] && NSAlternateKeyMask);
        NSLog(@"option is down: %d", optKeyDown);
        if(!optKeyDown)
            dragString = [NSString stringWithFormat: @"%@ %@", dragString, [[item webAddress] description]];
        else
            dragString = [NSString stringWithFormat: @"%@ <a href=\"%@\">%@</a>", dragString, [[item webAddress] description], [item title]];
    }
    return [pb setString: dragString forType: NSStringPboardType];
}

@end
