//
//  LJKit-URLLaunching.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Sep 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "LJKit-URLLaunching.h"


@implementation LJFriend (URLLaunching) 
- (void)launchRecentEntries
{
    [[NSWorkspace sharedWorkspace] openURL:[self recentEntriesHttpURL]];
}

- (void)launchFriendsPage
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: [NSString stringWithFormat: @"http://www.livejournal.com/~%@/friends", [self username]]]];
}

- (void)launchUserInfo
{
    [[NSWorkspace sharedWorkspace] openURL:[self userProfileHttpURL]];
}
@end

//------------------------------------------------------------------

@implementation LJGroup (URLLaunching)
- (void)launchMembersEntries
{
    [[NSWorkspace sharedWorkspace] openURL:[self membersEntriesHttpURL]];
}
@end

//------------------------------------------------------------------

@implementation LJAccount (URLLaunching)
- (void)launchRecentEntries
{
    [[NSWorkspace sharedWorkspace] openURL:[[[self journalArray] objectAtIndex:0] recentEntriesHttpURL]];
}

- (void)launchFriendsPage
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: [NSString stringWithFormat: @"http://www.livejournal.com/~%@/friends", [self username]]]];
}

- (void)launchUserInfo
{
    [[NSWorkspace sharedWorkspace] openURL:[self userProfileHttpURL]];
}
@end