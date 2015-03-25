//
//  XJMonth.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJYear.h"
#import "XJDay.h"
#import "XJCalendarProtocol.h"

@class XJDay;
@class XJYear;

@interface XJMonth : NSObject <XJCalendarProtocol> {
    NSMutableArray *days;
}

- (nonnull instancetype)initWithName:(int)theName inYear:(nonnull XJYear *)theYear NS_DESIGNATED_INITIALIZER;
@property (readonly) int monthName;
@property (readonly, copy, nonnull) NSString *displayName;
+ (int)numberForMonth: (nonnull NSString *)name;
@property (weak, nullable) XJYear *year;

@property (readonly) NSInteger numberOfDays;
- (BOOL)containsDay: (int)dayNumber;
- (nonnull XJDay *)day:(int)dayNumber;
- (nonnull XJDay *)createDayWithName:(int)dName NS_RETURNS_RETAINED;
- (nonnull XJDay *)dayAtIndex: (NSInteger) idx;
@property (readonly, strong, nonnull) XJDay *mostRecentDay;
@property (readonly, strong, nonnull) NSEnumerator *dayEnumerator;

- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target;
- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target searchType:(XJSearchType) type;

@property (readonly, copy, nonnull) NSArray *entriesInMonth;
@property (readonly) NSInteger numberOfEntriesInMonth;

- (nonnull NSURL *)urlForMonthArchiveForAccount: (nonnull LJAccount *)acct;

@property (readonly, copy, nonnull) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (nonnull id) plistType;

@end
