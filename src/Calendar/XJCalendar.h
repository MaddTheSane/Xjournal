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

- (nonnull instancetype)init;

@property (readonly) NSInteger numberOfYears;
- (BOOL)containsYear: (int)year;
- (nonnull XJYear *)year: (int)yearNumber;
@property (nonnull, readonly, strong) XJYear *mostRecentYear;
@property (nonnull, readonly, strong) LJEntry *mostRecentPost; // convenience!

- (nonnull XJYear *)addYearWithName: (int)yearName NS_RETURNS_RETAINED;
- (nonnull XJDay *)dayForCalendarDate:(nonnull NSCalendarDate *) theDate DEPRECATED_ATTRIBUTE;
- (nonnull XJDay *)dayForDate:(nonnull NSDate *) theDate;

- (nonnull XJMonth *)month:(int)mIdx ofYear:(int)yr;
- (nonnull XJDay *)day: (int)dayIdx ofMonth: (int)mIdx inYear:(int)yearIdx;

- (nonnull XJYear *)yearAtIndex:(NSInteger)idx;

@property (readonly, weak, nonnull) XJDay *today;

@property (readonly) NSInteger totalEntriesInCalendar;

@property (readonly, strong, nonnull) NSEnumerator *yearEnumerator;

- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target;
- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target searchType:(XJSearchType) type;

@property (readonly, copy, nonnull) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (nonnull id) plistType;
- (BOOL)writeToFile: (nonnull NSString *)filePath atomically: (BOOL)flag;
- (void)configureWithContentsOfFile: (nonnull NSString *)file;
@end
