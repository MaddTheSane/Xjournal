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

@class XJMonth;

enum {
    XJSearchSubjectOnly = 1,
    XJSearchBodyOnly = 2,
    XJSearchEntirePost = 3
};

@interface XJDay : NSObject {
    int postCount;
    int dayNumber;

    XJMonth *myMonth;

    NSMutableArray *entries;
}

- (id)initWithDayNumber:(int)theDayNumber month: (XJMonth *)mo andPostCount:(int)thePostCount;

- (int)postCount;
- (void)setPostCount:(int)newPCount;
- (void)validatePostCountAndUpdate: (int)newPostCount;

- (int)dayName;

- (void)setMonth: (XJMonth *)parentMonth;

- (BOOL)hasPosts;

- (NSCalendarDate *)calendarDate;
- (NSString *)dayOfWeek;

- (BOOL)hasDownloadedEntries;
- (void)downloadEntries;
- (LJEntry *)entryAtIndex:(int)idx;
- (LJEntry *)mostRecentEntry;
- (void)deleteEntryAtIndex:(int)idx;
- (void)deleteEntry: (LJEntry *)entry;

- (void)addPostedEntry:(LJEntry *)entry;
- (NSMutableArray *)makeMutable:(NSArray *)array;

- (NSString *)description;

- (id)propertyListRepresentation;
- (void)configureFromPropertyListRepresentation: (id) plistType;

- (NSArray *)entriesContainingString: (NSString *)target;
- (NSArray *)entriesContainingString: (NSString *)target searchType: (int)type;

- (NSURL *)urlForDayArchiveForAccount: (LJAccount *)acct;
- (NSString *)zeroizedString:(int)number;
@end
