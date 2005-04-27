//
//  FriendsFilterArrayController.m
//  Xjournal
//
//  Created by Fraser Speirs on 06/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "FriendsFilterArrayController.h"
#import <LJKit/LJKit.h>

NSString *FriendRowsType = @"XJFriendRowsType";

@implementation FriendsFilterArrayController
- (void)awakeFromNib {
	[table registerForDraggedTypes: [NSArray arrayWithObjects: FriendRowsType/*, NSURLPboardType*/, nil]];
}

- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard
{
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects: FriendRowsType, nil];
	
	/*
	 If the number of rows is not 1, then we only support our own types.
	 If there is just one row, then try to create an NSURL from the url
	 value in that row.  If that's possible, add NSURLPboardType to the
	 list of supported types, and add the NSURL to the pasteboard.
	 */
	if ([rows count] != 1)
	{
		[pboard declareTypes:typesArray owner:self];
	}
	else
	{
		// Try to create an URL
		// If we can, add NSURLPboardType to the declared types and write
		//the URL to the pasteboard; otherwise declare existing types
		/*
		 int row = [[rows objectAtIndex:0] intValue];
		NSString *urlString = [[[self arrangedObjects] objectAtIndex:row] valueForKey:@"url"];
		NSURL *url;
		if (urlString && (url = [NSURL URLWithString:urlString]))
		{
			typesArray = [typesArray arrayByAddingObject:NSURLPboardType];	
			[pboard declareTypes:typesArray owner:self];
			[url writeToPasteboard:pboard];	
		}
		else
		{
			*/
		[pboard declareTypes:typesArray owner:self];
		//}
	}
	// create new array of selected rows for remote drop
    // could do deferred provision, but keep it direct for clarity
	NSMutableArray *rowCopies = [NSMutableArray arrayWithCapacity:[rows count]];    
	NSEnumerator *rowEnumerator = [rows objectEnumerator];
	NSNumber *idx;
	while (idx = [rowEnumerator nextObject])
	{
		LJFriend *fr = [[self arrangedObjects] objectAtIndex:[idx intValue]];
		[rowCopies addObject: [fr username]];
	}
	// setPropertyList works here because we're using dictionaries, strings,
	// and dates; otherwise, archive collection to NSData...
	//[pboard setPropertyList:rowCopies forType:CopiedRowsType];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject: rowCopies];
	[pboard setData: data forType: FriendRowsType];
	
    return YES;

}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{

	LJFriend *friend = [[self arrangedObjects] objectAtIndex: rowIndex];
	
	if([[aTableColumn identifier] isEqualToString: @"username"]) {
		[aCell setDrawsBackground: YES];
		[(NSTextFieldCell *)aCell setBackgroundColor: [friend backgroundColor]];
		[aCell setTextColor: [friend foregroundColor]];
	}
	else  if([[aTableColumn identifier] isEqualToString: @"relationship"]) {
		[aCell setDrawsBackground: YES];
		switch([friend friendship]) {
			case LJMutualFriendship:
				[(NSTextFieldCell *)aCell setBackgroundColor: [NSColor colorWithCalibratedRed: 240.0/255.0 green: 255.0/255.0 blue: 240.0/255.0 alpha: 1.0]];
				break;
			case LJIncomingFriendship:
				[(NSTextFieldCell *)aCell setBackgroundColor: [NSColor colorWithCalibratedRed: 205/255.0 green: 220/255.0 blue: 243/255.0 alpha: 1.0]];
				break;
			case LJOutgoingFriendship:
				[(NSTextFieldCell *)aCell setBackgroundColor: [NSColor colorWithCalibratedRed: 215/255.0 green: 180/255.0 blue: 229/255.0 alpha: 1.0]];
				break;
			default:
				[aCell setDrawsBackground: NO];
		}
	}
	else if(![[aTableColumn identifier] isEqualToString: @"icon"]){
		[aCell setDrawsBackground: NO];
		[aCell setTextColor: [NSColor blackColor]];
	}
}

// ----------
// Search
// ----------
- (IBAction)search:(id)sender {
	[self setSearchString: [sender stringValue]];	
}

- (NSArray *)arrangeObjects:(NSArray *)objects
{
    NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    // case-insensitive search
    NSString *lowerSearch = [searchString lowercaseString];
    
	NSEnumerator *oEnum = [objects objectEnumerator];
    id item;	
    while (item = [oEnum nextObject])
	{
		// Use of local autorelease pool here is probably overkill,
		// but may be useful in a larger-scale application.
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if(searchString == nil || [searchString length] == 0) {
			if([(LJFriend *)item accountType] != nil && 
			   ![[(LJFriend *)item accountType] isEqualToString: @"community"]) {
				NSLog(@"%@ has an accountType not nil or community: %@", [item username], [item accountType]);	
				[matchedObjects addObject: item];
			}
			if(showUsers && [(LJFriend *)item accountType] == nil) {
				[matchedObjects addObject:item];
			}
			else if(showCommunities && [[(LJFriend *)item accountType] isEqualToString: @"community"]) {
				[matchedObjects addObject: item];
			}
		}
		else {
			
			NSString *lowerName = [[item valueForKeyPath:@"username"] lowercaseString];
			if ([lowerName rangeOfString:lowerSearch].location != NSNotFound) {
				
				if([(LJFriend *)item accountType] != nil && 
				   ![[(LJFriend *)item accountType] isEqualToString: @"community"]) {
					NSLog(@"%@ has an accountType not nil or community: %@", [item username], [item accountType]);	
					[matchedObjects addObject: item];
				}
				else if(showUsers && [(LJFriend *)item accountType] == nil)
					[matchedObjects addObject:item];
				else if(showCommunities && [[(LJFriend *)item accountType] isEqualToString: @"community"])
					[matchedObjects addObject: item];
			}
			else
			{
				lowerName = [[item valueForKeyPath:@"fullname"] lowercaseString];
				if ([lowerName rangeOfString:lowerSearch].location != NSNotFound)
				{
					if([(LJFriend *)item accountType] != nil && 
					   ![[(LJFriend *)item accountType] isEqualToString: @"community"]) {
						NSLog(@"%@ has an accountType not nil or community: %@", [item username], [item accountType]);	
						[matchedObjects addObject: item];
					}
					else if(showUsers && [[(LJFriend *)item accountType] isEqualToString: @""])
						[matchedObjects addObject:item];
					else if(showCommunities && [[(LJFriend *)item accountType] isEqualToString: @"community"])
						[matchedObjects addObject: item];
				}
			}
		}
		[pool release];
	}
	return [super arrangeObjects:matchedObjects];
}

// =========================================================== 
// - showUsers:
// =========================================================== 
- (BOOL)showUsers {
    return showUsers;
}

// =========================================================== 
// - setShowUsers:
// =========================================================== 
- (void)setShowUsers:(BOOL)flag {
	showUsers = flag;
	[self rearrangeObjects];
}

// =========================================================== 
// - showCommunities:
// =========================================================== 
- (BOOL)showCommunities {
    return showCommunities;
}

// =========================================================== 
// - setShowCommunities:
// =========================================================== 
- (void)setShowCommunities:(BOOL)flag {
	showCommunities = flag;
	[self rearrangeObjects];
}

// =========================================================== 
// - searchString:
// =========================================================== 
- (NSString *)searchString {
    return searchString; 
}

// =========================================================== 
// - setSearchString:
// =========================================================== 
- (void)setSearchString:(NSString *)aSearchString {
    if (searchString != aSearchString) {
        [aSearchString retain];
        [searchString release];
        searchString = aSearchString;
		[self rearrangeObjects];
    }
}

@end
