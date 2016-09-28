//
//  XJDay.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJDay.h"
#import "XJPreferences.h"

#import "LJEntryExtensions.h"
#import "XJAccountManager.h"

// Keys for Dictionary Representation
#define kPostCountKey @"PostCount"
#define kDayNumberKey @"DayNumber"
#define kEntryArrayKey @"Entries"

@implementation XJDay
@synthesize month = myMonth;
@synthesize postCount;
@synthesize dayName = dayNumber;

- (instancetype)initWithDayNumber:(int)theDayNumber month: (XJMonth *)mo andPostCount:(int)thePostCount
{
    if(self = [super init]) {
        postCount = thePostCount;
        dayNumber = theDayNumber;
        myMonth = mo;
    }
    return self;
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[kPostCountKey] = @(postCount);
    dictionary[kDayNumberKey] = @(dayNumber);

    NSMutableArray *array = [NSMutableArray array];
    if(entries) {
        for (LJEntry *oneentry in entries)
            [array addObject: [oneentry propertyListRepresentation]];
    }
    
    dictionary[kEntryArrayKey] = array;
    return dictionary;
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    NSAssert([plistType isKindOfClass: [NSDictionary class]], @"Non-dictionary supplied in configureFromPropertyListRepresentation");
    
    postCount = [plistType[kPostCountKey] intValue];
    dayNumber = [plistType[kDayNumberKey] intValue];
    NSArray *plistEntries = plistType[kEntryArrayKey];

    if([plistEntries count] > 0) {
        // if we don't actually have any entries, the entries array
        // needs to remain nil, so that -hasDownloadedEntries will
        // return the right value
        entries = [[NSMutableArray alloc] initWithCapacity: 30];

        for (id entry in plistEntries) {
            LJEntry *newEntry = [[LJEntry alloc] init];
            [newEntry configureFromPropertyListRepresentation: entry];
            [entries addObject: newEntry];
        }
    }
}

- (void)validatePostCountAndUpdate: (int)newPostCount
{
    if(newPostCount != postCount)
        [self downloadEntries];
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

- (NSDate*)date
{
    NSDateComponents *dc = [NSDateComponents new];
    dc.year = myMonth.year.yearName;
    dc.month = myMonth.monthName;
    dc.day = dayNumber;
    return [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:dc];
}

- (NSString *)dayOfWeek
{
    NSCalendar *aCal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dc = [aCal components:(NSCalendarUnitWeekday) fromDate:self.date];
    NSInteger day = dc.weekday;
    switch (day) {
            //TODO: get localized versions?
        case 1:
            return @"Sunday";
            break;
            
        case 2:
            return @"Monday";
            break;
            
        case 3:
            return @"Tuesday";
            break;
            
        case 4:
            return @"Wednesday";
            break;
            
        case 5:
            return @"Thursday";
            break;
            
        case 6:
            return @"Friday";
            break;
            
        default:
            NSAssert(NO, @"Got unknown week day, %li", (long)day);
        case 7:
            return @"Saturday";
            break;
    }
}

- (BOOL)hasDownloadedEntries
{
    return entries != nil;
}

- (void)downloadEntries
{
    entries = [[[[[XJAccountManager defaultManager] defaultAccount] defaultJournal] getEntriesForDay: self.date] mutableCopy];
    [self setPostCount: [entries count]];

    [[NSNotificationCenter defaultCenter] postNotificationName:XJEntryDownloadEndedNotification object:self];
} 

- (LJEntry *)entryAtIndex:(NSInteger)idx
{
    if(![self hasDownloadedEntries]) {
        [self downloadEntries];
    }

    return entries[idx];
}

- (LJEntry *)mostRecentEntry
{
    return [entries lastObject];
}

- (NSArray *)entriesContainingString: (NSString *)target
{
    return [self entriesContainingString: target searchType: XJSearchEntirePost];
}

- (NSArray *)entriesContainingString: (NSString *)target searchType: (XJSearchType)type
{
    NSMutableArray *array = [[NSMutableArray alloc] init];

    NSString *searchString = @"";
    
    for (LJEntry *entry in entries) {
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

- (void)deleteEntryAtIndex:(NSInteger)idx
{
    LJEntry *entry = [self entryAtIndex: idx];
    [entry removeFromJournal];
    [entries removeObjectAtIndex: idx];
    [self setPostCount: [entries count]];
}

- (void)deleteEntry: (LJEntry *)entry
{
	for(NSInteger i = 0; i < [entries count]; i++) {
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
    return [NSString stringWithFormat: @"%@ - %ld entries.", [[self date] description], (long)[self postCount]];
}

- (NSURL *)urlForDayArchiveForAccount: (LJAccount *)acct {
	NSString *base = [[myMonth urlForMonthArchiveForAccount: acct] absoluteString];
    NSString *url = [base stringByAppendingFormat: @"/%02d", dayNumber];
	return [NSURL URLWithString: url];
}

@end
