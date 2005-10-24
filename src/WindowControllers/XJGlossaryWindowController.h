//
//  XJGlossaryWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jan 23 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XJFileSystemItem.h"

#define kGlossaryWindowToolbarIdentifier @"GlossaryWindowToolbarIdentifier"
#define kGlossaryRefreshItemIdentifier @"GlossaryRefreshItemIdentifier"
#define kGlossaryInsertItemIdentifier @"GlossaryInsertItemIdentifier"
#define kGlossaryOpenItemIdentifier @"GlossaryOpenItemIdentifier"


@interface XJGlossaryWindowController : NSWindowController {
    IBOutlet NSOutlineView *outline;
    IBOutlet NSTextView *textView;
    NSMutableDictionary *toolbarItemCache;
    XJFileSystemItem *rootItem;
}

- (BOOL)directoryExists:(NSString *)path;
//- (void)loadStringsFromDirectory: (NSString *)dir;

- (IBAction)refresh:(id)sender;
//- (void)loadLocalGlossary;
//- (void)loadGlobalGlossary;

- (NSString *)localGlossaryPath;
- (NSString *)globalGlossaryPath;

- (IBAction)copySelectionToClipboard:(id)sender;
- (IBAction)openLocalGlossary:(id)sender;
- (IBAction)insertSelection:(id)sender;

//- (IBAction)setDisplayType: (id)sender;

- (void)checkForAndCreateGlossaryDirectory;
- (void)writeExampleGlossaryFile;
@end
