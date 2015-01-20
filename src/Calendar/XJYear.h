//
//  XJYear.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJMonth.h"
#import "XJCalendarProtocol.h"

@class LJAccount;
@class XJMonth;

@interface XJYear : NSObject <XJCalendarProtocol> {
    int name;
    NSMutableArray *months;
}

- (instancetype)initWithYearName:(int)yearName NS_DESIGNATED_INITIALIZER;
@property (readonly) int yearName;

@property (readonly) NSInteger numberOfMonths;
- (XJMonth *)month: (int)monthNumber;
@property (readonly, strong) XJMonth *mostRecentMonth;
- (BOOL)containsMonth: (int)monthNumber;

- (XJMonth *)createMonthWithName: (int)mName;

- (XJMonth *)monthAtIndex: (NSInteger) idx;
@property (readonly, strong) NSEnumerator *monthEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(XJSearchType) type;

@property (readonly) NSInteger numberOfEntriesInYear;

- (NSURL *)urlForYearArchiveForAccount: (LJAccount *)acct;

@end
