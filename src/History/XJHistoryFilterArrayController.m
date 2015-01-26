//
//  XJHistoryFilterArrayController.m
//  Xjournal
//
//  Created by Fraser Speirs on 12/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJHistoryFilterArrayController.h"


@implementation XJHistoryFilterArrayController
- (NSArray *)arrangeObjects:(NSArray *)objects
{
    NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
    if(searchString == nil || [searchString length] == 0) {
		[matchedObjects addObjectsFromArray: objects];
	}
	else {
		NSString *lowerSearch = [[self searchString] lowercaseString];
		
		NSEnumerator *oEnum = [objects objectEnumerator];
		id item;	
		while (item = [oEnum nextObject]) {
			NSString *content = [[item valueForKeyPath:@"content"] lowercaseString];
			NSString *mood = [[item valueForKeyPath: @"currentMood"] lowercaseString];
			NSString *music = [[item valueForKeyPath: @"currentMusic"] lowercaseString];
			NSString *subject = [[item valueForKeyPath: @"subject"] lowercaseString];
			
			// Search these from shortest to longest, in the hope that we can go 
			// faster by not searching content until we have to
			if(subject != nil && [subject rangeOfString: lowerSearch].location != NSNotFound) {
				[matchedObjects addObject: item];
			}
			else if(mood != nil && [mood rangeOfString: lowerSearch].location != NSNotFound) {
				[matchedObjects addObject: item];
			}	
			else if(music != nil && [music rangeOfString: lowerSearch].location != NSNotFound) {
				[matchedObjects addObject: item];
			}
			else if ([content rangeOfString:lowerSearch].location != NSNotFound) {
				[matchedObjects addObject: item];
			}
		}
	}
    return [super arrangeObjects:matchedObjects];
}

- (IBAction)search:(id)sender {
	[self setSearchString: [sender stringValue]];	
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
