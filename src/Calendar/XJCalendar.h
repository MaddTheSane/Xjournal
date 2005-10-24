//
//  XJCalendar.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJYear.h"

@interface XJCalendar : NSObject {
    NSMutableArray *years;
}

- (int)numberOfYears;
- (BOOL)containsYear: (int)year;
- (XJYear *)year: (int)yearNumber;
- (XJYear *)mostRecentYear;
- (LJEntry *)mostRecentPost; // convenience!

- (XJYear *)addYearWithName: (int)yearName;
- (XJDay *)dayForCalendarDate:(NSCalendarDate *) theDate;

- (XJMonth *)month:(int)mIdx ofYear:(int)yr;
- (XJDay *)day: (int)dayIdx ofMonth: (int)mIdx inYear:(int)yearIdx;

- (XJYear *)yearAtIndex:(int)idx;

- (XJDay *)today;

- (int)totalEntriesInCalendar;

- (NSEnumerator *)yearEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(int) type;

- (id)propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;
- (BOOL)writeToFile: (NSString *)filePath atomically: (BOOL)flag;
- (void)configureWithContentsOfFile: (NSString *)file;
@end
