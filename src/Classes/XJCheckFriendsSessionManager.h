//
//  XJCheckFriendsSessionManager.h
//  Xjournal
//
//  Created by Fraser Speirs on Wed Feb 19 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LJKit/LJKit.h>

typedef NS_ENUM(NSInteger, XJManagerCheckingMode) {
    XJManagerCheckingAllMode = 0,
    XJManagerCheckingGroupsMode
};


@interface XJCheckFriendsSessionManager : NSObject {

    LJCheckFriendsSession *session;
}

+ (XJCheckFriendsSessionManager *)sharedManager;

// Sets the mode of checking.  Pass XJManagerCheckingAllMode for all friends, XJManagerCheckingGroupsMode for specific groups.
@property XJManagerCheckingMode checkingMode;

// Returns the checking status for group
- (BOOL)isCheckingForGroup: (LJGroup *)grp;
- (void)setChecking: (BOOL)chk forGroup: (LJGroup *)grp;

// Starts checking friends in the way that is appropriate for the mode
- (void)startCheckingFriends;
- (void)stopCheckingFriends;

@property (getter=isChecking, readonly) BOOL checking;

// Notifcations
- (void)accountLoggedIn:(NSNotification *)aNotification;
@end
