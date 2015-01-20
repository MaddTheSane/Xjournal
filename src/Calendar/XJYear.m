//
//  XJYear.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import "XJYear.h"

#define kNameKey @"YearName"
#define kMonthListKey @"Months"

@implementation XJYear
- (instancetype)initWithYearName:(int)yearName
{
    if(self = [super init]) {
        months = [[NSMutableArray alloc] initWithCapacity: 12];
        name = yearName;
    }
    return self;
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[kNameKey] = @(name);

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [months objectEnumerator];
    id month;

    while(month = [enumerator nextObject])
        [array addObject: [month propertyListRepresentation]];

    dictionary[kMonthListKey] = array;
    return dictionary;
    
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    name = [plistType[kNameKey] intValue];
    //[months release];
    months = [[NSMutableArray alloc] initWithCapacity: 12];

    NSArray *plistMonths = plistType[kMonthListKey];
    NSEnumerator *enumerator = [plistMonths objectEnumerator];
    id plistMonth;
    while(plistMonth = [enumerator nextObject]) {
        XJMonth *month = [[XJMonth alloc] init];
        [month configureFromPropertyListRepresentation: plistMonth];
        [month setYear: self];
        [months addObject: month];
    }
    
}

- (NSInteger)numberOfEntriesInYear
{
    NSInteger total = 0;
    for (XJMonth *month in months) {
        total += [month numberOfEntriesInMonth];
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

    for (XJMonth *month in months) {
        [array addObjectsFromArray: [month entriesContainingString: target searchType: type]];
    }

    return array;
}

- (int)yearName
{
    return name;
}

- (NSInteger)numberOfMonths
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

- (XJMonth *)monthAtIndex: (NSInteger) idx
{
    return months[idx];
}

- (NSURL *)urlForYearArchiveForAccount: (LJAccount *)acct {
	NSString *base = [[[acct defaultJournal] recentEntriesHttpURL] absoluteString];
	NSString *url = [NSString stringWithFormat: @"%@%d", base, name];
	return [NSURL URLWithString: url];
}
@end
