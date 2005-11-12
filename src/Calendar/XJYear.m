//
//  XJYear.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJYear.h"
#import <LJKit/LJKit.h>

#define kNameKey @"YearName"
#define kMonthListKey @"Months"

@implementation XJYear
- (id)initWithYearName:(int)yearName
{
    if(self == [super init]) {
        months = [[NSMutableArray arrayWithCapacity: 12] retain];
        name = yearName;
        return self;
    }
    return nil;
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: [NSNumber numberWithInt: name] forKey: kNameKey];

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [months objectEnumerator];
    id month;

    while(month = [enumerator nextObject])
        [array addObject: [month propertyListRepresentation]];

    [dictionary setObject: array forKey: kMonthListKey];
    return dictionary;
    
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    name = [[plistType objectForKey: kNameKey] intValue];
    //[months release];
    months = [[NSMutableArray arrayWithCapacity: 12] retain];

    NSArray *plistMonths = [plistType objectForKey: kMonthListKey];
    NSEnumerator *enumerator = [plistMonths objectEnumerator];
    id plistMonth;
    while(plistMonth = [enumerator nextObject]) {
        XJMonth *month = [[XJMonth alloc] init];
        [month configureFromPropertyListRepresentation: plistMonth];
        [month setYear: self];
        [months addObject: month];
        //[month release];
    }
    
}

- (int)numberOfEntriesInYear
{
    int total = 0;
    NSEnumerator *enumerator = [months objectEnumerator];
    id month;
    while(month = [enumerator nextObject]) {
        total += [month numberOfEntriesInMonth];
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
    NSEnumerator *enumerator = [months objectEnumerator];
    XJMonth *month;

    while(month = [enumerator nextObject]) {
        [array addObjectsFromArray: [month entriesContainingString: target searchType: type]];
    }

    return array;
}

- (int)yearName
{
    return name;
}

- (int)numberOfMonths
{
    return [months count];
}

- (XJMonth *)month: (int)monthNumber
{
    NSEnumerator *enu = [months objectEnumerator];
    XJMonth *mo;

    while(mo = [enu nextObject]) {
        if([mo monthName] == monthNumber)
            return mo;
    }
    return [self createMonthWithName: monthNumber];
}

- (XJMonth *)mostRecentMonth
{
    return [months lastObject];
}

- (NSEnumerator *)monthEnumerator
{
    return [months objectEnumerator];
}

- (BOOL)containsMonth: (int)monthNumber
{
    return [self month: monthNumber] != nil;
}

- (XJMonth *)createMonthWithName: (int)mName
{
    XJMonth *theMonth = [[XJMonth alloc] initWithName: mName inYear: self];
    [months addObject: theMonth];
    [theMonth release];

    [months sortUsingSelector: @selector(compare:)];
    
    return theMonth;
}

- (NSComparisonResult)compare: (XJYear *)target
{
    int tName = [target yearName];
    
    if(name < tName)
        return NSOrderedAscending;

    if(name == tName)
        return NSOrderedSame;

    return NSOrderedDescending;
}

- (XJMonth *)monthAtIndex: (int) idx
{
    return [months objectAtIndex: idx];
}

- (NSURL *)urlForYearArchiveForAccount: (LJAccount *)acct {
	NSString *base = [[[acct defaultJournal] recentEntriesHttpURL] absoluteString];
	NSString *url = [NSString stringWithFormat: @"%@%d", base, name];
	return [NSURL URLWithString: url];
}
@end
