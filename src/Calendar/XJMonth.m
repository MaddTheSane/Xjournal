//
//  XJMonth.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJMonth.h"

#define JAN NSLocalizedString(@"January", @"")
#define FEB NSLocalizedString(@"February", @"")
#define MAR NSLocalizedString(@"March", @"")
#define APR NSLocalizedString(@"April", @"")
#define MAY NSLocalizedString(@"May", @"")
#define JUN NSLocalizedString(@"June", @"")
#define JUL NSLocalizedString(@"July", @"")
#define AUG NSLocalizedString(@"August", @"")
#define SEP NSLocalizedString(@"September", @"")
#define OCT NSLocalizedString(@"October", @"")
#define NOV NSLocalizedString(@"November", @"")
#define DEC NSLocalizedString(@"December", @"")

#define kNameKey @"MonthName"
#define kDayListKey @"Days"

@implementation XJMonth
@synthesize year;
@synthesize monthName = name;

- (instancetype)initWithName:(int)theName inYear:(XJYear *)theYear
{
    if(self = [super init]) {
        days = [[NSMutableArray alloc] initWithCapacity: 31];
        name = theName;
        year = theYear;
    }
    return self;
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[kNameKey] = @(name);

    NSMutableArray *array = [NSMutableArray array];

    for (XJDay *day in days)
        [array addObject: [day propertyListRepresentation]];

    dictionary[kDayListKey] = array;
    return [dictionary copy];
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    name = [plistType[kNameKey] intValue];
    days = [[NSMutableArray alloc] initWithCapacity: 31];
    
    NSArray *plistDays = plistType[kDayListKey];
    for (id plistDay in plistDays) {
        XJDay *day = [[XJDay alloc] init];
        [day configureFromPropertyListRepresentation: plistDay];
        [day setMonth: self];
        [days addObject: day];
    }
}

- (NSInteger)numberOfEntriesInMonth
{
    NSInteger total = 0;
    for (XJDay *day in days) {
        total += [day postCount];
    }
    return total;
}

- (NSArray *)entriesContainingString: (NSString *)target
{
    return [self entriesContainingString: target searchType: XJSearchEntirePost];
}

- (NSArray *)entriesContainingString: (NSString *)target searchType:(XJSearchType) type
{
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (XJDay *day in days) {
        [array addObjectsFromArray: [day entriesContainingString: target searchType: type]];
    }

    return array;
}

- (NSEnumerator *)dayEnumerator
{
    return [days objectEnumerator];
}

- (NSString *)displayName
{
    NSArray *months = @[JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC];
    return months[name-1];
}

+ (int)numberForMonth: (NSString *)displayName
{
    NSArray *months = @[JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC];
    for(int i=0; i < [months count] ; i++) {
        if([months[i] isEqualToString: displayName]) {
            return i+1;
        }
    }
    return -1;
}

- (NSInteger)numberOfDays { return [days count]; }

- (BOOL)containsDay: (int)dayNumber
{
    return [self day: dayNumber] != nil;
}

- (XJDay *)day:(int)dayNumber
{
    for (XJDay *d in days) {
        if (d.dayName == dayNumber) {
            return d;
        }
    }
    return [self createDayWithName: dayNumber];
}

- (XJDay *)mostRecentDay
{
    return [days lastObject];
}

- (XJDay *)createDayWithName:(int)dName
{
    XJDay *theDay = [[XJDay alloc] initWithDayNumber: dName month: self andPostCount: 0];
    [days addObject: theDay];

    [days sortUsingSelector: @selector(compare:)];
    
    return theDay;
}

- (NSComparisonResult)compare: (XJMonth *)target
{
    int tName = [target monthName];
    if(name < tName)
        return NSOrderedAscending;

    if(name == tName)
        return NSOrderedSame;

    return NSOrderedDescending;
}

- (XJDay *)dayAtIndex: (NSInteger) idx
{
    return days[idx];
}

- (NSArray *)entriesInMonth
{
    NSMutableArray *array = [NSMutableArray array];

    for (XJDay *day in days) {
        NSInteger i;
        for(i=0 ; i < [day postCount] ; i++) {
            [array addObject: [day entryAtIndex: i]];
        }
    }
    return [array copy];
}

- (NSURL *)urlForMonthArchiveForAccount: (LJAccount *)acct {
	NSString *base = [[year urlForYearArchiveForAccount: acct] absoluteString];
	NSString *url = [NSString stringWithFormat: @"%@/%02d", base, name];
	return [NSURL URLWithString: url];
}

@end
