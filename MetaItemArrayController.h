//
//  MetaItemArrayController.h
//  Xjournal
//
//  Created by Fraser Speirs on 07/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>

@class XJMetaLJGroup;

@interface MetaItemArrayController : NSArrayController {
	XJMetaLJGroup *allFriendsGroup;
	LJAccount *account;
	NSIndexSet *selectionIndexes;
	
	NSLock *contentLock;
	
	IBOutlet NSTableView *tableView;
}

- (LJAccount *)account;
- (void)setAccount:(LJAccount *)anAccount;

@end
