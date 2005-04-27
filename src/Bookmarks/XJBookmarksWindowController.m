//
//  XJBookmarksWindowController.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Jan 31 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarksWindowController.h"
#import <OmniBase/OmniBase.h>
#import "XJPreferences.h"

#define kBookmarkAutosaveName @"kBookmarkAutosaveName"

#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)

@implementation XJBookmarksWindowController

- (id)init
{
    if(self == [super initWithWindowNibName: @"Bookmarks"]) {
        [[self window] setFrameAutosaveName: kBookmarkAutosaveName];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:)
                                                     name: NSApplicationWillTerminateNotification
                                                   object: nil];
        
        return self;
    }
    return nil;
}

/*
 * Pay attention to the termination signal, to record the open
 * state of the window.
 */
- (void)applicationWillTerminate: (NSNotification *)note
{
    [PREFS setBool: [[self window] isVisible] forKey: kBookmarkWindowOpen];
}

/*
 * Setup stuff.
 */
- (void)windowDidLoad
{
    [outline registerForDraggedTypes: [NSArray arrayWithObjects: NSStringPboardType, nil]];
    [outline setAutosaveTableColumns: YES];
    // Set up NSToolbar
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: kBookmarkWindowToolbarIdentifier];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
    [toolbar release];

    [self refreshBookmarks: self];
}

/*
 * Refresh the bookmarks from disk.
 */
- (IBAction)refreshBookmarks:(id)sender
{
    if(!parser) {
        parser = [[XJSafariBookmarkParser alloc] init];
    }
    [parser refreshFromDisk];
    [outline reloadData];
}

// ----------------------------------------------------------------------------------------
// OutlineView Data Source - forwards most calls to the bookmark parser object.
// ----------------------------------------------------------------------------------------
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    return [parser outlineView: outlineView child: index ofItem: item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [parser outlineView: outlineView isItemExpandable: item];
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return [parser outlineView: outlineView numberOfChildrenOfItem: item];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [parser outlineView: outlineView objectValueForTableColumn: tableColumn byItem: item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    return [parser outlineView: outlineView writeItems: items toPasteboard: pboard];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item { return NO; }

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if(![[tableColumn identifier] isEqualToString: @"title"]) {
        if([item isKindOfClass: [XJBookmarkFolder class]])
            [(NSTextFieldCell*)cell setTextColor: [NSColor grayColor]];
        else
            [(NSTextFieldCell*)cell setTextColor: [NSColor blackColor]];
    }
}

/* 
I don't think this is a good idea, but I'm keeping it here for now.
 
- (void)showWindow:(id)sender {
	// Make the menu item toggle the window's visibility
	if([[self window] isVisible]) {
		[[self window] orderOut:self];
	}
	else {
		[super showWindow: sender];
	}
}
*/
// ----------------------------------------------------------------------------------------
// Toolbar button targets.
// ----------------------------------------------------------------------------------------
- (IBAction)expandAll:(id)sender
{
    XJBookmarkFolder *root = [parser rootItem];
    int i;

    for(i=0; i < [root numberOfChildren]; i++)
        [outline expandItem: [root childAtIndex: i] expandChildren: YES];
}

- (IBAction)collapseAll: (id) sender
{
    XJBookmarkFolder *root = [parser rootItem];
    int i;

    for(i=0; i < [root numberOfChildren]; i++)
        [outline collapseItem: [root childAtIndex: i] collapseChildren: YES];
}
@end