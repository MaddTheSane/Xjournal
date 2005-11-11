//
//  XJCheckFriendsSessionManager.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed Feb 19 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJCheckFriendsSessionManager.h"
#import "XJPreferences.h"
#import "XJAccountManager.h"

static XJCheckFriendsSessionManager *sharedManager;

@implementation XJCheckFriendsSessionManager
+ (XJCheckFriendsSessionManager *)sharedManager
{
    if(!sharedManager)
        sharedManager = [[XJCheckFriendsSessionManager alloc] init];
    return sharedManager;
}

- (id)init
{
    if([super init] == nil)
        return nil;

	 XJAccountManager *manager = [XJAccountManager defaultManager];
    
    // Configure myself from existing preferences
    checkingMode = [PREFS integerForKey: CHECKFRIENDS_GROUP_TYPE];
    session = [[LJCheckFriendsSession alloc] initWithAccount: [manager defaultAccount]];
    
    // register for the LJAccountDidLoginNotification event so we know to start checking friends
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountLoggedIn:)
                                                 name:LJAccountDidLoginNotification
                                               object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountRemoved:)
                                                 name: XJAccountWillRemoveNotification
                                               object:nil];
    return self;
}

- (void)dealloc
{
    [session release];
    [super dealloc];
}

// Observe when an account will be deleted and end its session
- (void)accountRemoved: (NSNotification *)note {
	NSLog(@"Got account will remove notification");
	if([[note object] isEqualTo: [session account]]) {
		[session release];
		session = nil;
	}
}

// Observe the notification of login
- (void)accountLoggedIn:(NSNotification *)aNotification
{
    XJAccountManager *manager = [XJAccountManager defaultManager];
    
    if(checkingMode == XJManagerCheckingGroupsMode) {
        NSEnumerator *allGroups = [[[manager defaultAccount] groupArray] objectEnumerator];
        LJGroup *group;
        // Populate the all-sessions dictionary with the expected checked groups
        while(group = [allGroups nextObject]) {
            if([XJPreferences shouldCheckForGroup: group]) {
                [session setChecking: YES forGroup: group];
            }
        }
    }
    
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsShouldCheck"] boolValue]) {
        NS_DURING
            [session startChecking];
        NS_HANDLER
            NSLog(@"Got exception: %@", [[localException userInfo] description]);
        NS_ENDHANDLER
    }
}


// Sets the mode of checking.  Pass XJManagerCheckingAllMode for all friends, XJManagerCheckingGroupsMode for specific groups.
- (void)setCheckingMode:(int)mode
{
    checkingMode = mode;
}

- (int)checkingMode
{
    return checkingMode;
}

// Returns the checking status for group
- (BOOL)isCheckingForGroup: (LJGroup *)grp
{
    // A session exists for the group.  Is it currently checking?
    return [[session checkGroupArray] containsObject: grp];
}

- (void)setChecking: (BOOL)chk forGroup: (LJGroup *)grp
{
    [session setChecking: chk forGroup: grp];
}

// Starts checking friends in the way that is appropriate for the mode
- (void)startCheckingFriends
{
    // How can we be sure that the session has figured out which groups to check?? 
    [session startChecking];
}

- (void)stopCheckingFriends
{
    [session stopChecking];
}

- (BOOL)isChecking
{
    NSAssert(session != nil, @"Sesssion is nil!!");
    return [session isChecking];
}
@end
