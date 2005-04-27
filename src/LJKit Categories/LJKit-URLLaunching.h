//
//  LJKit-URLLaunching.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Sep 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LJKit/LJKit.h>

@interface LJFriend (URLLaunching) 
- (void)launchRecentEntries;
- (void)launchFriendsPage;
- (void)launchUserInfo;
@end

@interface LJGroup (URLLaunching)
- (void)launchMembersEntries;
@end

@interface LJAccount (URLLaunching)
- (void)launchRecentEntries;
- (void)launchFriendsPage;
- (void)launchUserInfo;
@end