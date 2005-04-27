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

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [[acct friendArray] objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        if([object birthdayIsWithinAlertPeriod: 7])
            [array addObject: object];
    }
    return array;
}

- (NSArray *)friendsWithBirthdaysThisMonth
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];

    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *enumerator = [[acct friendArray] objectEnumerator];
    id object;

    while (object = [enumerator nextObject]) {
        if([object birthdayIsThisMonth])
            [array addObject: object];
    }
    return array;
}

@end
