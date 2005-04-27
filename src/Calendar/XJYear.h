//
//  XJYear.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJMonth.h"

@class LJAccount;
@class XJMonth;

@interface XJYear : NSObject {
    int name;
    NSMutableArray *months;
}

- (id)initWithYearName:(int)yearName;
- (int)yearName;

- (int)numberOfMonths;
- (XJMonth *)month: (int)monthNumber;
- (XJMonth *)mostRecentMonth;
- (BOOL)containsMonth: (int)monthNumber;

- (XJMonth *)createMonthWithName: (int)mName;

- (XJMonth *)monthAtIndex: (int) idx;
- (NSEnumerator *)monthEnumerator;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType:(int) type;

- (int)numberOfEntriesInYear;

- (NSURL *)urlForYearArchiveForAccount: (LJAccount *)acct;

- (id)propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;
@end
