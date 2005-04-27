//
//  MetaItemArrayController.m
//  Xjournal
//
//  Created by Fraser Speirs on 07/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "MetaItemArrayController.h"
#import "XJMetaLJGroup.h"

NSString *DroppableRowType = @"XJFriendRowsType";

@implementation MetaItemArrayController
- (void)awakeFromNib {
	[tableView registerForDraggedTypes: [NSArray arrayWithObject: DroppableRowType]];
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;
    
	if(row > [[self arrangedObjects] count]-1)
		row = [[self arrangedObjects] count]-1;
	
     // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropOn];
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op
{
    if (row < 1)
	{
		row = 1;
	}
    
	// Can we get rows from another document?  If so, add them, then return.
	NSArray *newRows = [NSKeyedUnarchiver unarchiveObjectWithData: [[info draggingPasteboard] dataForType:DroppableRowType]];
	
	if (newRows)
	{
		NSLog(@"Got %d dropped rows: %@", [newRows count], [newRows description]);
		if([[self arrangedObjects] count] > row) {
			LJGroup *group = [[self arrangedObjects] objectAtIndex: row];
			NSLog(@"Dropped on group %@", [group name]);
			int i;
			for(i=0; i < [newRows count]; i++) {
				NSString *uname = [newRows objectAtIndex: i];
				LJFriend *fr = [[self account] friendNamed: uname];
				NSLog(@"Added %@ to %@", [fr username], [group name]);
				[group addFriend: fr];
			}
			
			NSLog([[group memberArray] description]);
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"XJGroupsChangedNotification"
																object: group];
			return YES;
		}
    }
	
    return NO;
}

// -----
// Metaitem
// -----
- (NSArray *)arrangeObjects:(NSArray *)objects {
	if(!contentLock)
		contentLock = [[NSLock alloc] init];
	
	NSLog(@"arrangeObjects: %@", [objects description]);
	
	[contentLock lock];
	NSMutableArray *arr = [NSMutableArray array];
	
	if(!allFriendsGroup) {
		allFriendsGroup = [[XJMetaLJGroup alloc] initWithAccount: [self account]];
		[allFriendsGroup setName: @"All Friends"];	
	}
	
	[arr addObject: allFriendsGroup];
	if(objects != nil)
		[arr addObjectsFromArray: objects];

	[contentLock unlock];
	
	return [super arrangeObjects: arr];
}


// =========================================================== 
// - account:
// =========================================================== 
- (LJAccount *)account {
    return account; 
}

// =========================================================== 
// - setAccount:
// =========================================================== 
- (void)setAccount:(LJAccount *)anAccount {
    if (account != anAccount) {
        [anAccount retain];
        [account release];
        account = anAccount;

		[allFriendsGroup setAccount: [self account]];
    }
}
@end
