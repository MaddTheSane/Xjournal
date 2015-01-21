//
//  XJDay.h
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XJMonth.h"
#import <LJKit/LJKit.h>
#import "XJCalendarProtocol.h"

@class XJMonth;

@interface XJDay : NSObject <XJCalendarProtocol> {
    NSMutableArray *entries;
}

@property (weak) XJMonth *month;

- (instancetype)initWithDayNumber:(int)theDayNumber month: (XJMonth *)mo andPostCount:(int)thePostCount NS_DESIGNATED_INITIALIZER;

@property NSInteger postCount;
- (void)validatePostCountAndUpdate: (int)newPostCount;

@property (readonly) int dayName;

- (void)setMonth: (XJMonth *)parentMonth;

@property (readonly) BOOL hasPosts;

@property (readonly, copy) NSCalendarDate *calendarDate;
@property (readonly, copy) NSString *dayOfWeek;

@property (readonly) BOOL hasDownloadedEntries;
- (void)downloadEntries;
- (LJEntry *)entryAtIndex:(NSInteger)idx;
@property (readonly, strong) LJEntry *mostRecentEntry;
- (void)deleteEntryAtIndex:(NSInteger)idx;
- (void)deleteEntry: (LJEntry *)entry;

- (void)addPostedEntry:(LJEntry *)entry;

@property (readonly, copy) NSString *description;

@property (readonly, copy) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType: (XJSearchType)type;

- (NSURL *)urlForDayArchiveForAccount: (LJAccount *)acct;
@end
