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

NS_ASSUME_NONNULL_BEGIN

@interface XJCalendar : NSObject <XJCalendarProtocol> {
    NSMutableArray *years;
}

- (instancetype)init;

@property (readonly) NSInteger numberOfYears;
- (BOOL)containsYear: (int)year;
- (XJYear *)year: (int)yearNumber;
@property (readonly, strong) XJYear *mostRecentYear;
@property (readonly, strong) LJEntry *mostRecentPost; // convenience!

- (XJYear *)addYearWithName: (int)yearName NS_RETURNS_RETAINED;
- (XJDay *)dayForCalendarDate:(NSCalendarDate *) theDate DEPRECATED_ATTRIBUTE;
- (XJDay *)dayForDate:(NSDate *) theDate;

- (XJMonth *)month:(int)mIdx ofYear:(int)yr;
- (XJDay *)day: (int)dayIdx ofMonth: (int)mIdx inYear:(int)yearIdx;

- (XJYear *)yearAtIndex:(NSInteger)idx;

@property (readonly, weak) XJDay *today;

@property (readonly) NSInteger totalEntriesInCalendar;

@property (readonly, strong) NSEnumerator *yearEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(XJSearchType) type;

@property (readonly, copy) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;
- (BOOL)writeToFile: (NSString *)filePath atomically: (BOOL)flag;
- (void)configureWithContentsOfFile: (NSString *)file;
@end

NS_ASSUME_NONNULL_END
