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

- (nonnull instancetype)initWithYearName:(int)yearName NS_DESIGNATED_INITIALIZER;
@property (readonly) int yearName;

@property (readonly) NSInteger numberOfMonths;
- (nonnull XJMonth *)month: (int)monthNumber;
@property (readonly, weak, nonnull) XJMonth *mostRecentMonth;
- (BOOL)containsMonth: (int)monthNumber;

- (nonnull XJMonth *)createMonthWithName: (int)mName;

- (nonnull XJMonth *)monthAtIndex: (NSInteger) idx;
@property (readonly, strong, nonnull) NSEnumerator *monthEnumerator;

- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target;
- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target searchType:(XJSearchType) type;

@property (readonly) NSInteger numberOfEntriesInYear;

- (nonnull NSURL *)urlForYearArchiveForAccount: (nonnull LJAccount *)acct;

@end
