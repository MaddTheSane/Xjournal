//
//  LJAccount-BirthdayExtensions.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 24 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LJKit/LJKit.h>

@interface LJAccount (BirthdayExtensions)

- (NSArray *)friendsWithBirthdaysThisWeek;
- (NSArray *)friendsWithBirthdaysThisMonth;

@end
