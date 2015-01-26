//
//  XJExportManager.h
//  Xjournal
//
//  Created by Fraser Speirs on 09/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XJExportManager : NSObject {
	id account;
	
	NSMutableDictionary *historyTree;
}

- (NSString *)accountUsername;
- (NSString *)accountFullName;
- (NSURL *)accountURL;

- (int)numberOfEntries;
- (NSDictionary *)entryAtIndex:(int)i;
- (NSDictionary *)entryAtPath:(NSString *)path;

// Ordered array of entries
- (NSArray *)entriesOrderedByDateInOrder:(BOOL)ascending;


// Returns array of NSNumber, each representing a year
// Sorted in ascending order
- (NSArray *)years;

// Returns an array of NSNumber, each representing a month
// Ascending
- (NSArray *)monthsOfYear: (NSNumber *)year;

// Returns an array of NSNumber, each representing a month
// Ascending
- (NSArray *)daysOfMonth:(NSNumber *)month ofYear: (NSNumber *)year;

// Returns an array of NSDictionary, each representing an entry for the specified day
- (NSArray *)entriesOfDay:(NSNumber *)day ofMonth:(NSNumber *)month ofYear:(NSNumber *)year;

@end
