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
- (id)initWithName:(int)theName inYear:(XJYear *)theYear
{
    if(self == [super init]) {
        days = [[NSMutableArray arrayWithCapacity: 31] retain];
        name = theName;
        year = theYear;
        return self;
    }
    return nil;
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: [NSNumber numberWithInt: name] forKey: kNameKey];

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [days objectEnumerator];
    id day;

    while(day = [enumerator nextObject])
        [array addObject: [day propertyListRepresentation]];

    [dictionary setObject: array forKey: kDayListKey];
    return dictionary;
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    name = [[plistType objectForKey: kNameKey] intValue];
    days = [[NSMutableArray arrayWithCapacity: 31] retain];
    
    NSArray *plistDays = [plistType objectForKey: kDayListKey];
    NSEnumerator *enumerator = [plistDays objectEnumerator];
    id plistDay;
    while(plistDay = [enumerator nextObject]) {
        XJDay *day = [[XJDay alloc] init];
        [day configureFromPropertyListRepresentation: plistDay];
        [day setMonth: self];
        [days addObject: day];
        //[day release];
    }
        
}

- (int)monthName {return name;}

- (int)numberOfEntriesInMonth
{
    int total = 0;
    NSEnumerator *enumerator = [days objectEnumerator];
    id day;
    while(day = [enumerator nextObject]) {
        total += [day postCount];
    }
    return total;
}

- (NSArray *)entriesContainingString: (NSString *)target
{
    return [self entriesContainingString: target searchType: 3];
}

- (NSArray *)entriesContainingString: (NSString *)target searchType:(int) type
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [days objectEnumerator];
    XJDay *day;

    while(day = [enumerator nextObject]) {
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
    NSArray *months = [NSArray arrayWithObjects: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, nil];
    return [months objectAtIndex: name-1];
}

+ (int)numberForMonth: (NSString *)displayName
{
    NSArray *months = [NSArray arrayWithObjects: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC, nil];
    int i;
    for(i=0; i < [months count] ; i++) {
        if([[months objectAtIndex: i] isEqualToString: displayName]) {
            return i+1;
        }
    }
    return -1;
}

- (XJYear *)year{ return year; }

- (void)setYear: (XJYear *)parentYear
{
    year = parentYear;
}

- (int)numberOfDays { return [days count]; }

- (BOOL)containsDay: (int)dayNumber
{
    return [self day: dayNumber] != nil;
}

- (XJDay *)day:(int)dayNumber
{
    NSEnumerator *enu = [days objectEnumerator];
    XJDay *d;

    while(d = [enu nextObject]) {
        if([d dayName] == dayNumber) {
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
    [theDay release];

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

- (XJDay *)dayAtIndex: (int) idx
{
    return [days objectAtIndex: idx];
}

- (NSArray *)entriesInMonth
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *dayEnum = [days objectEnumerator];
    XJDay *day;

    while(day = [dayEnum nextObject]) {
        int i;
        for(i=0 ; i < [day postCount] ; i++) {
            [array addObject: [day entryAtIndex: i]];
        }
    }
    return array;
}

- (NSURL *)urlForMonthArchiveForAccount: (LJAccount *)acct {
	NSString *base = [[year urlForYearArchiveForAccount: acct] absoluteString];
	NSString *zeroizedName = [self zeroizedString: name];
	NSString *url = [NSString stringWithFormat: @"%@/%@", base, zeroizedName];
	return [NSURL URLWithString: url];
}

- (NSString *)zeroizedString:(int)number {
    if(number < 10)
        return [NSString stringWithFormat: @"0%d", number];
    else
        return [NSString stringWithFormat: @"%d", number];
}
@end
