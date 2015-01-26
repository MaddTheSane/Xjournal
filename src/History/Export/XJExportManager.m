//
//  XJExportManager.m
//  Xjournal
//
//  Created by Fraser Speirs on 09/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJExportManager.h"
#import <LJKit/LJKit.h>
#import "LJEntryExtensions.h"

@interface XJExportManager (Private)
- (id)initWithAccount:(LJAccount *)acct;
- (id)account;
- (void)setAccount:(id)anAccount;

- (void)createHistoryTree;
- (NSMutableDictionary *)dictionaryForYear:(NSNumber *)year;
- (NSMutableDictionary *)dictionaryForMonth:(NSNumber *)month ofYear:(NSNumber *)year;
- (NSMutableArray *)arrayForDay:(NSNumber *)day ofMonth:(NSNumber *)month ofYear:(NSNumber *)year;

- (LJLightwieghtHistoryIndexItem *)lightIndexItemAtIndex:(int)i;
@end

@implementation XJExportManager
- (NSString *)accountUsername {
	return [[self account] username];
}

- (NSString *)accountFullName {
	return [[self account] fullname];
}

- (NSURL *)accountURL {
	return [[self account] recentEntriesHttpURL];
}

- (int)numberOfEntries {
	LJHistory *history = [[self account] history];
	return [[[history lightIndex] entries] count];
}

- (NSDictionary *)entryAtIndex:(int)i {
	LJLightwieghtHistoryIndexItem *item = [self lightIndexItemAtIndex: i];
	return [self entryAtPath: [item filePath]];
}

- (NSDictionary *)entryAtPath:(NSString *)path {
	LJEntry *entry = [[LJEntry alloc] init];
	[entry configureWithContentsOfFile: path];
	
	return [[entry autorelease] propertyListRepresentation];	
}

// Returns array of NSNumber, each representing a year
// Sorted in ascending order
- (NSArray *)years {
	return [[historyTree allKeys] sortedArrayUsingSelector: @selector(compare:)];
}

	// Returns an array of NSNumber, each representing a month
	// Ascending
- (NSArray *)monthsOfYear: (NSNumber *)year {
	return [[[historyTree objectForKey: year] allKeys] sortedArrayUsingSelector: @selector(compare:)];
}

	// Returns an array of NSNumber, each representing a month
	// Ascending
- (NSArray *)daysOfMonth:(NSNumber *)month ofYear: (NSNumber *)year {
	NSDictionary *yearDict = [historyTree objectForKey: year];
	NSDictionary *monthDict = [yearDict objectForKey: month];
	
	return [[monthDict allKeys] sortedArrayUsingSelector: @selector(compare:)];
}

	// Returns an array of NSDictionary, each representing an entry for the specified day
- (NSArray *)entriesOfDay:(NSNumber *)day ofMonth:(NSNumber *)month ofYear:(NSNumber *)year {
	NSDictionary *yearDict = [historyTree objectForKey: year];
	NSDictionary *monthDict = [yearDict objectForKey: month];
	NSArray *dayArray = [monthDict objectForKey: day];
	
	// Create all the LJEntries and add them to an array
	NSMutableArray *arr = [NSMutableArray array];
	NSEnumerator *en = [dayArray objectEnumerator];
	LJLightwieghtHistoryIndexItem *item;
	while(item = [en nextObject]) {
		LJEntry *entry = [[LJEntry alloc] init];
		[entry configureWithContentsOfFile: [item filePath]];
		[arr addObject: [entry propertyListRepresentation]];
		[entry release];
	}
	
 	return arr;
}

//=========================================================== 
//  - dealloc:
//=========================================================== 
- (void)dealloc {
    [account release];
    [super dealloc];
}
@end

@implementation XJExportManager (Private)
- (id)initWithAccount:(LJAccount *)acct {
	self = [super init];
	if(self) {
		NSLog(@"Initing exportmanager for %@", [acct username]);
		[self setAccount: acct];
		
		[self createHistoryTree];
	}
	return self;
}
//=========================================================== 
//  account 
//=========================================================== 
- (LJAccount *)account {
    return (LJAccount *)account; 
}
- (void)setAccount:(LJAccount *)anAccount {
    [anAccount retain];
    [account release];
    account = anAccount;
}

- (void)createHistoryTree {
	[historyTree release];
	historyTree = [[NSMutableDictionary dictionary] retain];
	int i;
	for(i=0; i < [self numberOfEntries]; i++) {
		LJLightwieghtHistoryIndexItem *entry = [self lightIndexItemAtIndex: i];
		NSDate *entryDate = [entry date];
		NSCalendarDate *date = [NSCalendarDate dateWithString: [entryDate description] calendarFormat: @"%Y-%m-%d %H:%M:%S"];
		int year = [date yearOfCommonEra];
		int month = [date monthOfYear];
		int day = [date dayOfMonth];
		
		
		NSMutableArray *thisDay = [self arrayForDay: [NSNumber numberWithInt: day]
											  ofMonth: [NSNumber numberWithInt: month]
											   ofYear: [NSNumber numberWithInt: year]];
		[thisDay addObject: entry];
		//NSLog(@"Added entry dated %@ to month %d-%d-%d", [date description], year, month, day);
	}
	
	[[historyTree description] writeToFile: [@"~/Desktop/dump.txt" stringByExpandingTildeInPath] atomically: NO];
}

- (NSMutableDictionary *)dictionaryForYear:(NSNumber *)year {
	if(![historyTree objectForKey: year]) {
		[historyTree setObject: [NSMutableDictionary dictionary] forKey: year];
	}
	return [historyTree objectForKey: year];
}

- (NSMutableDictionary *)dictionaryForMonth:(NSNumber *)month ofYear:(NSNumber *)year {
	NSMutableDictionary *yearDict = [self dictionaryForYear: year];
	if(![yearDict objectForKey: month]) {
		[yearDict setObject: [NSMutableDictionary dictionary] forKey: month];
	}
	return [yearDict objectForKey: month];
}

- (NSMutableArray *)arrayForDay:(NSNumber *)day ofMonth:(NSNumber *)month ofYear:(NSNumber *)year {
	NSMutableDictionary *monthDict = [self dictionaryForMonth: month ofYear: year];
	
	if(![monthDict objectForKey: day]) {
		[monthDict setObject: [NSMutableArray array] forKey: day];
	}
	return [monthDict objectForKey: day];
}

- (LJLightwieghtHistoryIndexItem *)lightIndexItemAtIndex:(int)i {
	LJHistory *history = [[self account] history];
	LJLightwieghtHistoryIndex *idx = [history lightIndex];
	return [[idx entries] objectAtIndex: i];	
}
@end


