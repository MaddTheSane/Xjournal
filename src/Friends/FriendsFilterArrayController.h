//
//  FriendsFilterArrayController.h
//  Xjournal
//
//  Created by Fraser Speirs on 06/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FriendsFilterArrayController : NSArrayController {
	BOOL showUsers;
	BOOL showCommunities;
	NSString *searchString;
	
	IBOutlet NSTableView *table;
}

- (IBAction)search:(id)sender;

- (BOOL)showUsers;
- (void)setShowUsers:(BOOL)flag;

- (BOOL)showCommunities;
- (void)setShowCommunities:(BOOL)flag;

- (NSString *)searchString;
- (void)setSearchString:(NSString *)aSearchString;


@end
