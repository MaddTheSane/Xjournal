//
//  XJDay.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJDay.h"
#import "XJPreferences.h"
#import <OmniFoundation/OmniFoundation.h>

#import "LJEntryExtensions.h"
#import "XJAccountManager.h"

#define DEBUG NO

// Keys for Dictionary Representation
#define kPostCountKey @"PostCount"
#define kDayNumberKey @"DayNumber"
#define kEntryArrayKey @"Entries"

@implementation XJDay
- (id)initWithDayNumber:(int)theDayNumber month: (XJMonth *)mo andPostCount:(int)thePostCount
{
    if(self == [super init]) {
        postCount = thePostCount;
        dayNumber = theDayNumber;
        myMonth = mo;
        return self;
    }
    return nil;
}

- (void)dealloc
{
    // myMonth is not retained
    [entries release];
    [super dealloc];
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setIntValue: postCount forKey: kPostCountKey];
    [dictionary setIntValue: dayNumber forKey: kDayNumberKey];

    NSMutableArray *array = [NSMutableArray array];
    if(entries) {
        NSEnumerator *entryEnumerator = [entries objectEnumerator];
        LJEntry *oneentry;
        
        while(oneentry = [entryEnumerator nextObject])
            [array addObject: [oneentry propertyListRepresentation]];
    }
    
    [dictionary setObject: array forKey: kEntryArrayKey];
    return dictionary;
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    NSAssert([plistType isKindOfClass: [NSDictionary class]], @"Non-dictionary supplied in configureFromPropertyListRepresentation");
    NSArray *plistEntries;
    NSEnumerator *plistEnumerator;
    
    postCount = [plistType intForKey: kPostCountKey];
    dayNumber = [plistType intForKey: kDayNumberKey];
    plistEntries = [plistType objectForKey: kEntryArrayKey];

    if([plistEntries count] > 0) {
        // if we don't actually have any entries, the entries array
        // needs to remain nil, so that -hasDownloadedEntries will
        // return the right value
        plistEnumerator = [plistEntries objectEnumerator];
        id entry;
        //[entries release];
        entries = [[NSMutableArray arrayWithCapacity: 30] retain];

        while(entry = [plistEnumerator nextObject]) {
            LJEntry *newEntry = [[LJEntry alloc] init];
            [newEntry configureFromPropertyListRepresentation: entry];
            [entries addObject: newEntry];
            //[entry release];
        }
    }
}

- (void)setPostCount:(int)newPCount
{
    postCount = newPCount;
}

- (int)postCount { return postCount; }

- (void)validatePostCountAndUpdate: (int)newPostCount
{
    if(newPostCount != postCount)
        [self downloadEntries];
}


- (int)dayName { return dayNumber; }

- (void)setMonth: (XJMonth *)parentMonth
{
    myMonth = parentMonth;
}

- (BOOL)hasPosts { return postCount != 0; }

- (NSComparisonResult)compare: (XJDay *)target
{
    int tName = [target dayName];
    if(dayNumber < tName)
        return NSOrderedAscending;

    if(dayNumber == tName)
        return NSOrderedSame;

    return NSOrderedDescending;
}

- (NSCalendarDate *)calendarDate
{
    NSString *dateString = [NSString stringWithFormat: @"%d-%d-%d", [[myMonth year] yearName], [myMonth monthName], dayNumber];
    NSString *calendarFormat = @"%Y-%m-%d";
    return [NSCalendarDate dateWithString: dateString calendarFormat: calendarFormat];
}

- (NSString *)dayOfWeek
{
    int day = [[self calendarDate] dayOfWeek];

    if(day == 0)
        return @"Sunday";

    if(day == 1)
        return @"Monday";

    if(day == 2)
        return @"Tuesday";

    if(day == 3)
        return @"Wednesday";

    if(day == 4)
        return @"Thursday";

    if(day == 5)
        return @"Friday";

    return @"Saturday";

}

- (BOOL)hasDownloadedEntries
{
    return entries != nil;
}

- (void)downloadEntries
{
	[entries release];
    entries = [[self makeMutable: [[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] getEntriesForDay: [self calendarDate]]] retain];
    [self setPostCount: [entries count]];

    [[NSNotificationCenter defaultCenter] postNotificationName:XJEntryDownloadEndedNotification object:self];
} 

- (LJEntry *)entryAtIndex:(int)idx
{

    if(![self hasDownloadedEntries]) {
        [self downloadEntries];
    }

    return [entries objectAtIndex: idx];
}

- (LJEntry *)mostRecentEntry
{
    return [entries lastObject];
}

- (NSArray *)entriesContainingString: (NSString *)target
{
    return [self entriesContainingString: target searchType: 3];
}

- (NSArray *)entriesContainingString: (NSString *)target searchType: (int)type
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [entries objectEnumerator];
    LJEntry *entry;

    NSString *searchString = @"";
    
    while(entry = [enumerator nextObject]) {
        switch(type) {
            case XJSearchSubjectOnly:
                if([entry subject])
                    searchString = [entry subject];
                else
                    searchString = @"";
                break;
            case XJSearchBodyOnly:
                searchString = [entry content];
                break;
            case XJSearchEntirePost:
                searchString = [NSString stringWithFormat: @"%@ %@", ([entry subject] != nil) ? [entry subject] : @"", [entry content]];
                break;
        }

        if(target != nil) {
            NSRange foundRange = [searchString rangeOfString: target options: NSCaseInsensitiveSearch range: NSMakeRange(0, [searchString length])];
            if(foundRange.location != NSNotFound) {
                [array addObject: entry];
            }
        }
    }

    return array;
}

- (void)deleteEntryAtIndex:(int)idx
{
    LJEntry *entry = [self entryAtIndex: idx];
    [entry removeFromJournal];
    [entries removeObjectAtIndex: idx];
    [self setPostCount: [entries count]];
}

- (void)deleteEntry: (LJEntry *)entry
{
	int i;
	for(i = 0; i < [entries count]; i++) {
		LJEntry *iter = [self entryAtIndex:i];
		if([iter itemID] == [entry itemID])
			[self deleteEntryAtIndex:i];
	}
}

- (void)addPostedEntry:(LJEntry *)entry
{
    [entries addObject: entry];
    [self setPostCount: [entries count]];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"%@ - %d entries.", [[self calendarDate] description], [self postCount]];
}

- (NSURL *)urlForDayArchiveForAccount: (LJAccount *)acct {
	NSString *base = [[myMonth urlForMonthArchiveForAccount: acct] absoluteString];
	NSString *zeroizedName = [self zeroizedString: dayNumber];
	NSString *url = [NSString stringWithFormat: @"%@/%@", base, zeroizedName];
	return [NSURL URLWithString: url];
}

- (NSString *)zeroizedString:(int)number
{
    if(number < 10)
        return [NSString stringWithFormat: @"0%d", number];
    else
        return [NSString stringWithFormat: @"%d", number];
}

- (NSMutableArray *)makeMutable:(NSArray *)array
{
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity: [array count]+5];
    [temp addObjectsFromArray: array];
    return temp;
}
@end
