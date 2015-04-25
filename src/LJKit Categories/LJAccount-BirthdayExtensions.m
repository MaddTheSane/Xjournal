//
//  LJAccount-BirthdayExtensions.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 24 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJAccount-BirthdayExtensions.h"
#import "XJAccountManager.h"
#import "LJFriend-ABExtensions.h"

@implementation LJAccount (BirthdayExtensions)

- (NSArray *)friendsWithBirthdaysThisWeek
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];

    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (id object in acct.friendArray) {
        if([object birthdayIsWithinAlertPeriod: 7])
            [array addObject: object];
    }
    return [array copy];
}

- (NSArray *)friendsWithBirthdaysThisMonth
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];

    NSMutableArray *array = [[NSMutableArray alloc] init];

    for (id object in acct.friendArray) {
        if([object birthdayIsThisMonth])
            [array addObject: object];
    }
    return [array copy];
}

@end
