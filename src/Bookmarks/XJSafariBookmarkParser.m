//
//  XJSafariBookmarkParser.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed Jan 29 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJSafariBookmarkParser.h"
#import <AddressBook/AddressBook.h>

@interface XJSafariBookmarkParser () <NSOutlineViewDataSource>
- (void)parseAddressBookIntoFolder: (XJBookmarkFolder *)root;
- (void)parseDict:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root;
- (void)parseList:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root;
- (void)parseLeaf:(NSDictionary *)leaf withRootFolder: (XJBookmarkFolder *)root;
@end

@implementation XJSafariBookmarkParser
- (instancetype)init {
    if (self = [super init]) {
		
    }
    return self;
}

/*
 * Refresh the bookmarks from the Safari plist.
 */
- (void)refreshFromDisk
{
    NSString *path = [@"~/Library/Safari/Bookmarks.plist" stringByExpandingTildeInPath];
    NSDictionary *bookmarks = [NSDictionary dictionaryWithContentsOfFile: path];
    rootFolder = [XJBookmarkFolder folderWithTitle: @"__root_item__"];
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

/*
 * Reads all the URLs from Address Book and makes them children
 * of the given XJBookmarkFolder
 */
- (void)parseAddressBookIntoFolder: (XJBookmarkFolder *)root
{
    NSArray *everyone;
    NSEnumerator *enumerator;
    id key;
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    XJBookmarkFolder *abFolder = [XJBookmarkFolder folderWithTitle: NSLocalizedString(@"Address Book", @"")];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    everyone = [book people];

    for (ABPerson *person in everyone) {
        NSString *data, *fname, *lname, *cname = nil;

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
                    dictionary[cname] = data;
                }
            }
            else {
                dictionary[[NSString stringWithFormat: @"%@ %@", fname, lname]] = data;
            }
        }
    }

    // Now, take all the Name/URL key-values and make then into XJBookmarkItems
    enumerator = [[[dictionary allKeys] sortedArrayUsingSelector: @selector(compare:)] objectEnumerator];
    while(key = [enumerator nextObject]) {
        [abFolder addChild: [XJBookmarkItem bookmarkWithTitle: key address: [NSURL URLWithString: dictionary[key]]]];
    }
            
    [root addChild: abFolder];
}

/*
 * Take a dictionary and parse it for bookmarks.  This is a (sort-of) recursive method
 * since bookmark folders can be arbitrarily nested (AFAIK)
 */
- (void)parseDict:(NSDictionary *)dict withRootFolder: (XJBookmarkFolder *)root
{
    NSString *type = dict[@"WebBookmarkType"];

    if([type isEqualToString: @"WebBookmarkTypeList"]) {
        // If it's a list is has a key "Children" which is an array of Leaf dictionaries
        NSArray *kids = dict[@"Children"];
        NSEnumerator *enumer = [kids objectEnumerator];
        NSDictionary *child;

        while(child = [enumer nextObject]) {
            if([child[@"WebBookmarkType"] isEqualToString: @"WebBookmarkTypeList"])
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
    NSString *folderTitle = dict[@"Title"];
    thisFolder = [XJBookmarkFolder folderWithTitle: folderTitle];

    // If it's a list is has a key "Children" which is an array of Leaf dictionaries
    NSArray *kids = dict[@"Children"];
    NSEnumerator *enumer = [kids objectEnumerator];
    NSDictionary *child;

    while(child = [enumer nextObject]) {
        if([child[@"WebBookmarkType"] isEqualToString: @"WebBookmarkTypeList"])
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
    NSDictionary *uriDict = leaf[@"URIDictionary"];
    NSString *title = uriDict[@"title"], *url = leaf[@"URLString"];

    if(title != nil & url!= nil) {
        [root addChild: [XJBookmarkItem bookmarkWithTitle: title address: [NSURL URLWithString: url]]];
    }
}

// ----------------------------------------------------------------------------------------
// OutlineView Data Source
// ----------------------------------------------------------------------------------------
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if(item == nil)
        return [rootFolder childAtIndex: index];
    else {
        return [(XJBookmarkFolder*)item childAtIndex: index];
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

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
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
            return [NSString stringWithFormat: @"%ld items", (long)[item numberOfChildren]];
    }
    return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pb
{
    NSEnumerator *enumer = [items objectEnumerator];
    id item;
    NSString *dragString = @"";

    [pb declareTypes:@[NSStringPboardType] owner:self];
    
    while(item = [enumer nextObject]) {
        BOOL optKeyDown = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask);
        NSLog(@"option is down: %d", optKeyDown);
        if(!optKeyDown)
            dragString = [NSString stringWithFormat: @"%@ %@", dragString, [[item webAddress] description]];
        else
            dragString = [NSString stringWithFormat: @"%@ <a href=\"%@\">%@</a>", dragString, [[item webAddress] description], [item title]];
    }
    return [pb setString: dragString forType: NSStringPboardType];
}

@end
