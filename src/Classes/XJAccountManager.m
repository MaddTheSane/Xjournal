//
//  AccountManager.m
//  Xjournal
//
//  Created by Fraser Speirs on Sun Apr 06 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJAccountManager.h"
#import "XJPreferences.h"
#import "NetworkConfig.h"
#import "XJGrowlManager.h"

#define kAccountsPrefKey @"Accounts"
#define kDefaultAccountUsernameKey @"DefaultUsername"
#define kChecksFriendsKey @"ChecksFriends"
#define kChecksGroupsKey @"ChecksGroups"
#define kCheckedGroupsKey @"CheckedGroups"
#define kUsesSSLKey @"UsesSSL"
#define kServerURLKey @"ServerURL"
/*
 Accounts information is stored in an NSDictionary in prefs.
 
 account1 =>
     doesCheck => BOOL
     checksGroups => BOOL
     checkedGroups => {group1, group2, etc}
     usesSSL => BOOL
     server => string
 */
 
static XJAccountManager *manager;

@interface XJAccountManager (Private)
- (void)gatherAccountsFromPreferences;
- (void)logInAccount: (LJAccount *)acct;
- (void)saveToPreferences;
@end

@implementation XJAccountManager
+ (XJAccountManager *)defaultManager
{
    if(!manager)
        manager = [[XJAccountManager alloc] init];
    return manager;
}

- (id)init
{
    self = [super init];
	if(self) {
		[self setCfSessions: [NSMutableDictionary dictionary]];
		[self setAccounts: [NSMutableArray array]];
		[self setPasswordCache: [NSMutableDictionary dictionaryWithCapacity: 5]];
		[self gatherAccountsFromPreferences];
		
		loginCheckTimer = [[NSTimer scheduledTimerWithTimeInterval: 60
															target: self
														  selector: @selector(checkLoginStatus:)
														  userInfo: nil
														   repeats: YES] retain];
		
		// Want to be notified of app. quit so we can write the accounts to prefs
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(applicationWillTerminate:)
													 name: NSApplicationWillTerminateNotification
												   object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(accountLoggedIn:)
													 name: LJAccountDidLoginNotification
												   object: nil];
	}
    return self;
}

//=========================================================== 
//  - dealloc:
//=========================================================== 
- (void)dealloc {
    [self setPasswordCache: nil];
    [self setAccounts: nil];
    [self setCfSessions: nil];
	
    [super dealloc];
}

- (void)checkLoginStatus: (NSTimer *)timer {
	int i;
	for(i=0; i < [[self accounts] count]; i++) {
		if(![[[self accounts] objectAtIndex: i] isLoggedIn]) {
			[NSThread detachNewThreadSelector: @selector(logInAccount:) 
									 toTarget: self
								   withObject: [[self accounts] objectAtIndex: i]];
		}
	}
}

- (void)applicationWillTerminate: (NSNotification *)note {
	[self saveToPreferences];
}

- (void)accountLoggedIn: (NSNotification *)note {
	LJAccount *acc = [note object];
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSDictionary *prefsInfo = [defs objectForKey: kAccountsPrefKey];
	NSDictionary *acctInfo = [prefsInfo objectForKey: [acc username]];
		
	if([[acctInfo objectForKey: kChecksFriendsKey] boolValue]) {
		[self setAccount:acc checksFriends: YES startChecking: NO];
		NSNumber *checkedGroupMask = [acctInfo objectForKey: kCheckedGroupsKey];
		if(checkedGroupMask)
			[[self cfSessionForAccount: acc] setCheckGroupMask: [checkedGroupMask intValue]];
	
		[[self cfSessionForAccount: [note object]] startChecking];
	}
}

// ===========================================================
// - passwordCache:
// ===========================================================
- (NSMutableDictionary *)passwordCache {
    return passwordCache; 
}

// ===========================================================
// - setPasswordCache:
// ===========================================================
- (void)setPasswordCache:(NSMutableDictionary *)aPasswordCache {
    if (passwordCache != aPasswordCache) {
        [aPasswordCache retain];
        [passwordCache release];
        passwordCache = aPasswordCache;
    }
}

// ===========================================================
// - accounts:
// ===========================================================
- (NSMutableArray *)accounts {
    return accounts; 
}

// ===========================================================
// - setAccounts:
// ===========================================================
- (void)setAccounts:(NSMutableArray *)anAccounts {
    if (accounts != anAccounts) {
        [anAccounts retain];
        [accounts release];
        accounts = anAccounts;
    }
}


- (LJAccount *)accountWithUsername: (NSString *)accName {
	NSEnumerator *en = [[self accounts] objectEnumerator];
	id acc;
	while(acc = [en nextObject]) {
		if([[acc username] isEqualToString: accName])
			return acc;
	}
	return nil;
}

//=========================================================== 
//  defaultAccount 
//=========================================================== 
- (LJAccount *)defaultAccount {
    return defaultAccount; 
}
- (void)setDefaultAccount:(LJAccount *)aDefaultAccount {
    defaultAccount = aDefaultAccount;
}

// ===========================================================
// Accounts KVO Accessors
// ===========================================================
///////  accounts  ///////

- (unsigned int)countOfAccounts 
{
    return [[self accounts] count];
}

- (id)objectInAccountsAtIndex:(unsigned int)index 
{
    return [[self accounts] objectAtIndex:index];
}

- (void)insertObject:(id)anObject inAccountsAtIndex:(unsigned int)index 
{
	BOOL firstAccount = [[self accounts] count] == 0;
    [[self accounts] insertObject:anObject atIndex:index];
	[self logInAccount: anObject];
}

- (void)removeObjectFromAccountsAtIndex:(unsigned int)index 
{
    [[self accounts] removeObjectAtIndex:index];
}

- (void)replaceObjectInAccountsAtIndex:(unsigned int)index withObject:(id)anObject 
{
    [[self accounts] replaceObjectAtIndex:index withObject:anObject];
}

//=========================================================== 
// - cfSessions:
//=========================================================== 
- (NSMutableDictionary *)cfSessions {
    return cfSessions; 
}

//=========================================================== 
// - setCfSessions:
//=========================================================== 
- (void)setCfSessions:(NSMutableDictionary *)aCfSessions {
    [aCfSessions retain];
    [cfSessions release];
    cfSessions = aCfSessions;
}

- (void)setAccount: (LJAccount *)account checksFriends: (BOOL)flag startChecking:(BOOL)shouldStart {
	if(!flag) { // Turning checking off for account
		LJCheckFriendsSession *session = [[self cfSessions] objectForKey: [account username]];
		[session stopChecking];
		[[self cfSessions] removeObjectForKey: [account username]];
	}
	else { // Want checking on, but if it's already on, stuff it.
		if([[self cfSessions] objectForKey: [account username]] == nil) {
			LJCheckFriendsSession *session = [[LJCheckFriendsSession alloc] initWithAccount: account];
			[[self cfSessions] setObject: session forKey: [account username]];
			NSLog(@"Created CF session for %@", [account username]);

			if(shouldStart)
				[session startChecking];
			[session release];
		}
	}
}

- (BOOL)accountChecksFriends: (LJAccount *)acc {
	return [self cfSessionForAccount: acc] != nil;
}

// If this method returns nil, the account doesn't check
- (LJCheckFriendsSession *)cfSessionForAccount: (LJAccount *)acct {
	return [[self cfSessions] objectForKey: [acct username]];
}
@end

@implementation XJAccountManager (Private)
- (void)gatherAccountsFromPreferences {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *defaultUsername = [defs objectForKey: kDefaultAccountUsernameKey];
	NSLog(@"Default username: %@", defaultUsername);
	NSDictionary *prefsInfo = [defs objectForKey: kAccountsPrefKey];
	
	if(prefsInfo) {
		NSEnumerator *en = [[prefsInfo allKeys] objectEnumerator];
		NSString *acctName;
		
		while(acctName = [en nextObject]) {
			NSLog(@"Found %@ in preferences", acctName);
			
			NSDictionary *accountInfo = [prefsInfo objectForKey: acctName];
			
			LJAccount *acc = [[LJAccount alloc] initWithUsername: acctName];
			[acc setUsesSSL: [[accountInfo objectForKey: kUsesSSLKey] boolValue]];
			[[acc server] setURL: [NSURL URLWithString: [accountInfo objectForKey: kServerURLKey]]];
			
			[[self mutableArrayValueForKey: @"accounts"] addObject: acc];
			
			if([[acc username] isEqualToString: defaultUsername]) {
				[self setDefaultAccount: acc];
				NSLog(@"Setting default account: %@", [acc username]);
			}
			
			[acc release];
			[NSThread detachNewThreadSelector: @selector(logInAccount:) toTarget: self withObject: acc];
		}
	}
	
	if([self defaultAccount] == nil && [[self accounts] count] > 0) {
		NSLog(@"Picking %@ as default username", [[accounts objectAtIndex: 0] username]);
		[self setDefaultAccount: [accounts objectAtIndex: 0]];
	}
	
}

- (void)saveToPreferences {
	NSLog(@"Saving accounts to preferences");
	NSMutableDictionary *accountsDict = [NSMutableDictionary dictionary];
	
	 NSEnumerator *en = [[self accounts] objectEnumerator];
	 LJAccount *acc;
	 	 
	 while(acc = [en nextObject]) {
		 NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		 
		 // Save the checkfriends info
		 LJCheckFriendsSession *session = [self cfSessionForAccount: acc];
		 // Do we check at all?
		 [dict setObject: [NSNumber numberWithBool: session != nil]
				  forKey: kChecksFriendsKey];
		 
		 if(session)
			 [dict setObject: [NSNumber numberWithInt: [session checkGroupMask]] forKey: kCheckedGroupsKey];
	 
		 // Save the server
		 [dict setObject: [[[acc server] URL] absoluteString] forKey: kServerURLKey];
		 [dict setObject: [NSNumber numberWithBool: [acc usesSSL]] forKey: kUsesSSLKey];
		 
		 [accountsDict setObject: dict forKey: [acc username]];
	 }

	 [[NSUserDefaults standardUserDefaults] setObject: accountsDict forKey: kAccountsPrefKey];
	 [[NSUserDefaults standardUserDefaults] setObject: [[self defaultAccount] username] forKey: kDefaultAccountUsernameKey];
}

- (void)logInAccount: (LJAccount *)acct {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"Logging in account %@", [acct username]);
	
	NS_DURING
		[acct loginWithPassword: [acct password] flags: LJDefaultLoginFlags];
		NSLog(@"Logged in %@", [acct username]);
		[acct downloadFriends];
	NS_HANDLER
		[[XJGrowlManager defaultManager] notifyWithTitle: [NSString stringWithFormat: @"Login Failed: %@", [acct username]]
											 description: [localException reason]
										notificationName: XJGrowlAccountDidNotLogInNotification
												  sticky: NO];
	NS_ENDHANDLER
	
	[pool release];
}
@end