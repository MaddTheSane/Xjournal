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
- (instancetype)init
{
    if(self = [super init]) {
        years = [[NSMutableArray alloc] initWithCapacity: 10];
    }
    return self;
}


- (id)propertyListRepresentation
{
    NSMutableArray *array = [NSMutableArray array];

    for (XJYear *oneYear in years) {
        [array addObject: [oneYear propertyListRepresentation]];
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[kYearListKey] = array;
    
    return dictionary; // is already autoreleased
}

- (void)configureFromPropertyListRepresentation: (id) plistType
{
    NSArray *plistYears = plistType[kYearListKey];
    //[years release];
    years = [[NSMutableArray alloc] initWithCapacity: 10];

    for (id plistYear in plistYears) {
        XJYear *oneYear = [[XJYear alloc] init];
        [oneYear configureFromPropertyListRepresentation: plistYear];
        [years addObject: oneYear];
    }
}

- (BOOL)writeToFile: (NSString *)filePath atomically: (BOOL)flag
{
    id plist = [self propertyListRepresentation];
    return [plist writeToFile: filePath atomically: flag];
}

- (void)configureWithContentsOfFile: (NSString *)file
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: file];
    [self configureFromPropertyListRepresentation: dict];
}

- (NSInteger)numberOfYears
{
    return [years count];
}

- (BOOL)containsYear: (int)year
{
    for (XJYear *yr in years) {
        if ([yr yearName] == year)
            return YES;
    }
    return NO;
}

- (XJYear *)year: (int)yearNumber
{
    for (XJYear *yr in years) {
        if (yr.yearName == yearNumber) {
            return yr;
        }
    }
    return [self addYearWithName: yearNumber];
}

- (XJYear *)yearAtIndex:(NSInteger)idx
{
    return years[idx];
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
    return [self entriesContainingString: target searchType: XJSearchEntirePost];
}

- (NSArray *)entriesContainingString: (NSString *)target searchType:(XJSearchType) type
{
    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (XJYear *year in years) {
        [array addObjectsFromArray: [year entriesContainingString: target searchType: type]];
    }

    return array;
}

- (XJYear *)addYearWithName: (int)yearName
{
    XJYear *theYear = [[XJYear alloc] initWithYearName: yearName];
    [years addObject: theYear];
    [years sortUsingSelector: @selector(compare:)];
    return theYear;
}

- (XJDay *) dayForCalendarDate:(NSCalendarDate *) theDate
{
    return [self dayForDate: theDate];
}

- (XJDay *) dayForDate:(NSDate *) theDate
{
    NSCalendar *aCal = [NSCalendar calendarWithIdentifier: NSCalendarIdentifierGregorian];
    NSInteger yr = 0, month = 0, day = 0;
    [aCal getEra:NULL year:&yr month:&month day:&day fromDate:theDate];
    return [self day:(int)day ofMonth:(int)month inYear:(int)yr];
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
    return [self dayForDate: today];
}

- (NSInteger)totalEntriesInCalendar
{
    NSInteger total = 0;
    for (XJYear *year in years) {
        total += [year numberOfEntriesInYear];
    }

    return total;
}
@end
