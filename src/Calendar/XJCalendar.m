//
//  XJCalendar.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJCalendar.h"
#import "XJMonth.h"
#import "XJDay.h"

#define kYearListKey @"Years"
#define DEBUG NO

@implementation XJCalendar
- (id)init
{
    if(self = [super init]) {
        years = [[NSMutableArray arrayWithCapacity: 10] retain];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [years release];
    [super dealloc];
}

- (id)propertyListRepresentation
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [years objectEnumerator];
    XJYear *oneYear;

    while(oneYear = [enumerator nextObject]) {
        [array addObject: [oneYear propertyListRepresentation]];
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject: array forKey: kYearListKey];
    
    return dictionary; // is already autoreleased
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    NSArray *plistYears = [plistType objectForKey: kYearListKey];
    //[years release];
    years = [[NSMutableArray arrayWithCapacity: 10] retain];

    NSEnumerator *enumerator = [plistYears objectEnumerator];
    id plistYear;

    while(plistYear = [enumerator nextObject]) {
        XJYear *oneYear = [[XJYear alloc] init];
        [oneYear configureFromPropertyListRepresentation: plistYear];
        [years addObject: oneYear];
        //[oneYear release];
    }
}

- (BOOL)writeToFile: (NSString *)filePath atomically: (BOOL)flag
{
    id plist = [[self propertyListRepresentation] retain];
    return [plist writeToFile: filePath atomically: flag];
}

- (void)configureWithContentsOfFile: (NSString *)file
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: file];
    [self configureFromPropertyListRepresentation: dict];
}

- (int)numberOfYears
{
    return [years count];
}

- (BOOL)containsYear: (int)year
{
    NSEnumerator *enu = [years objectEnumerator];
    XJYear *yr;
    
    while(yr = [enu nextObject]) {
        if([yr yearName] == year)
            return YES;
    }
    return NO;
}

- (XJYear *)year: (int)yearNumber
{
    NSEnumerator *enu = [years objectEnumerator];
    XJYear *yr;
    
    while(yr = [enu nextObject]) {
        if([yr yearName] == yearNumber) 
            return yr;
    }
    return [self addYearWithName: yearNumber];
}

- (XJYear *)yearAtIndex:(int)idx
{
    return [years objectAtIndex: idx];
}

- (XJYear *)mostRecentYear
{
    return [years lastObject];
}

- (LJEntry *)mostRecentPost
{
    XJYear *year = [self mostRecentYear];
    XJMonth *mo = [year mostRecentMonth];
    XJDay *day = [mo mostRecentDay];
    return [day mostRecentEntry];
}

- (NSEnumerator *)yearEnumerator
{
    return [years objectEnumerator];
}

- (NSArray *)entriesContainingString: (NSString *)target
{
    return [self entriesContainingString: target searchType: 3];
}

- (NSArray *)entriesContainingString: (NSString *)target searchType:(int) type
{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [years objectEnumerator];
    XJYear *year;

    while(year = [enumerator nextObject]) {
        [array addObjectsFromArray: [year entriesContainingString: target searchType: type]];
    }

    return array;
}

- (XJYear *)addYearWithName: (int)yearName
{
    XJYear *theYear = [[XJYear alloc] initWithYearName: yearName];
    [years addObject: theYear];
    [theYear release];
    [years sortUsingSelector: @selector(compare:)];
    return theYear;
}

- (XJDay *) dayForCalendarDate:(NSCalendarDate *) theDate
{
    XJYear *y = [self year: [theDate yearOfCommonEra]];
    XJMonth *m = [y month: [theDate monthOfYear]];
    return [m day: [theDate dayOfMonth]];
}

- (XJMonth *)month:(int)mIdx ofYear:(int)yr
{
    XJYear *y = [self year: yr];
    return [y month: mIdx];
}

- (XJDay *)day: (int)dayIdx ofMonth: (int)mIdx inYear:(int)yearIdx
{
    XJYear *y = [self year: yearIdx];
    XJMonth *m = [y month: mIdx];
    return [m day: dayIdx];
}

- (XJDay *)today
{
    NSDate *today = [NSDate date];
    return [self dayForCalendarDate: [today dateWithCalendarFormat: nil timeZone: nil]];
}

- (int)totalEntriesInCalendar
{
    int total = 0;
    NSEnumerator *enumerator = [years objectEnumerator];
    id year;
    while(year = [enumerator nextObject])
        total += [year numberOfEntriesInYear];

    return total;
}
@end
