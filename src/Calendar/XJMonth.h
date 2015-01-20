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

- (instancetype)initWithName:(int)theName inYear:(XJYear *)theYear NS_DESIGNATED_INITIALIZER;
@property (readonly) int monthName;
@property (readonly, copy) NSString *displayName;
+ (int)numberForMonth: (NSString *)name;
@property (weak) XJYear *year;

@property (readonly) NSInteger numberOfDays;
- (BOOL)containsDay: (int)dayNumber;
- (XJDay *)day:(int)dayNumber;
- (XJDay *)createDayWithName:(int)dName;
- (XJDay *)dayAtIndex: (NSInteger) idx;
@property (readonly, strong) XJDay *mostRecentDay;
@property (readonly, strong) NSEnumerator *dayEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(XJSearchType) type;

@property (readonly, copy) NSArray *entriesInMonth;
@property (readonly) NSInteger numberOfEntriesInMonth;

- (NSURL *)urlForMonthArchiveForAccount: (LJAccount *)acct;

@property (readonly, copy) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;

@end
