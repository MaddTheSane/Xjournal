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

@class XJDay;
@class XJYear;

@interface XJMonth : NSObject {
    int name;
    XJYear * year;
    NSMutableArray *days;
}

- (id)initWithName:(int)theName inYear:(XJYear *)theYear;
- (int)monthName;
- (NSString *)displayName;
+ (int)numberForMonth: (NSString *)name;
- (XJYear *)year;
- (void)setYear: (XJYear *)parentYear;

- (int)numberOfDays;
- (BOOL)containsDay: (int)dayNumber;
- (XJDay *)day:(int)dayNumber;
- (XJDay *)createDayWithName:(int)dName;
- (XJDay *)dayAtIndex: (int) idx;
- (XJDay *)mostRecentDay;
- (NSEnumerator *)dayEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(int) type;

- (NSArray *)entriesInMonth;
- (int)numberOfEntriesInMonth;

- (NSURL *)urlForMonthArchiveForAccount: (LJAccount *)acct;

- (id)propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;

- (NSString *)zeroizedString:(int)number;
@end
