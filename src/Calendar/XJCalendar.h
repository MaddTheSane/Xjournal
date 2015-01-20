//
//  XJCalendar.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJYear.h"
#import "XJCalendarProtocol.h"

@interface XJCalendar : NSObject <XJCalendarProtocol> {
    NSMutableArray *years;
}

@property (readonly) NSInteger numberOfYears;
- (BOOL)containsYear: (int)year;
- (XJYear *)year: (int)yearNumber;
@property (readonly, strong) XJYear *mostRecentYear;
@property (readonly, strong) LJEntry *mostRecentPost; // convenience!

- (XJYear *)addYearWithName: (int)yearName;
- (XJDay *)dayForCalendarDate:(NSCalendarDate *) theDate; //NSCalendarDate is deprecated!
- (XJDay *)dayForDate:(NSDate *) theDate;

- (XJMonth *)month:(int)mIdx ofYear:(int)yr;
- (XJDay *)day: (int)dayIdx ofMonth: (int)mIdx inYear:(int)yearIdx;

- (XJYear *)yearAtIndex:(NSInteger)idx;

@property (readonly, strong) XJDay *today;

@property (readonly) NSInteger totalEntriesInCalendar;

@property (readonly, strong) NSEnumerator *yearEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(XJSearchType) type;

@property (readonly, copy) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;
- (BOOL)writeToFile: (NSString *)filePath atomically: (BOOL)flag;
- (void)configureWithContentsOfFile: (NSString *)file;
@end
