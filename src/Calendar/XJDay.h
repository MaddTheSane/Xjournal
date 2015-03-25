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

@property (weak, nullable) XJMonth *month;

- (nonnull instancetype)initWithDayNumber:(int)theDayNumber month: (nonnull XJMonth *)mo andPostCount:(int)thePostCount NS_DESIGNATED_INITIALIZER;

@property NSInteger postCount;
- (void)validatePostCountAndUpdate: (int)newPostCount;

@property (readonly) int dayName;

@property (readonly) BOOL hasPosts;

@property (readonly, copy, nullable) NSCalendarDate *calendarDate DEPRECATED_ATTRIBUTE;
@property (readonly, copy, nonnull) NSDate *date;
@property (readonly, copy, nonnull) NSString *dayOfWeek;

@property (readonly) BOOL hasDownloadedEntries;
- (void)downloadEntries;
- (nonnull LJEntry *)entryAtIndex:(NSInteger)idx;
@property (readonly, weak, nonnull) LJEntry *mostRecentEntry;
- (void)deleteEntryAtIndex:(NSInteger)idx;
- (void)deleteEntry: (nonnull LJEntry *)entry;

- (void)addPostedEntry:(nonnull LJEntry *)entry;

@property (readonly, copy, nonnull) NSString *description;

@property (readonly, copy, nonnull) id propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (nonnull id) plistType;

- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target;
- (nonnull NSArray *)entriesContainingString: (nonnull NSString *)target searchType: (XJSearchType)type;

- (nonnull NSURL *)urlForDayArchiveForAccount: (nonnull LJAccount *)acct;
@end
