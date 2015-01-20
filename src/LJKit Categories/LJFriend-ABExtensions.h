//
//  LJFriend-ABExtensions.h
//  Xjournal
//
//  Created by Fraser Speirs on Sun Apr 13 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <LJKit/LJKit.h>

@interface LJFriend (ABExtensions)

- (void)associateABRecord: (ABRecord *)record;
- (ABRecord *)addressBookRecord;
- (void)unassociateABRecord;
- (BOOL)hasAddressCard;

- (NSString *)uniqueId;
- (NSString *)chatURL;
- (NSImage *)abImage;
- (NSString *)abName;
- (void)addAddressCardAndEdit: (BOOL)shouldEdit;

- (NSString *)email;
- (NSString *)emailWithDomain: (NSString *)domain;
@end

@interface LJFriend (Birthdays)
- (BOOL)birthdayIsToday;
- (BOOL)birthdayIsWithinAlertPeriod: (int)alertPeriod;
- (BOOL)birthdayIsThisMonth;
- (void)addBirthdayToCalendarNamed:(NSString *)calendarName;
@end


@interface LJFriend (Comparisons)
- (NSComparisonResult)compareUserCommunity: (id)otherFriend;
- (NSComparisonResult)compareUserCommunityDescending: (id)otherFriend;
- (NSComparisonResult)compareUserCommunity: (id)otherFriend descending: (BOOL)descending;

- (NSComparisonResult)compareUsername: (id)otherFriend;
- (NSComparisonResult)compareUsernameDescending: (id)otherFriend;
- (NSComparisonResult)compareUsername: (id)otherFriend descending: (BOOL)descending;

- (NSComparisonResult)compareFullName: (id)otherFriend;
- (NSComparisonResult)compareFullNameDescending: (id)otherFriend;
- (NSComparisonResult)compareFullName: (id)otherFriend descending: (BOOL)descending;

- (NSComparisonResult)compareRelationship: (id)otherFriend;
- (NSComparisonResult)compareRelationshipDescending: (id)otherFriend;
- (NSComparisonResult)compareRelationship: (id)otherFriend descending: (BOOL)descending;
@end