//
//  AccountManager.m
//  Xjournal
//
//  Created by Fraser Speirs on Sun Apr 06 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJAccountManager.h"
#import "XJPreferences.h"
#import "XJAppDelegate.h"

#import "Xjournal-Swift.h"

#define kAccountsPrefKey @"Accounts"
#define kDefaultAccountNameKey @"DefaultAccount"

static XJAccountManager *manager;

@implementation XJAccountManager
{
    NSMutableDictionary *accounts, *passwordCache;
    NSString *defaultUsername;
    LJAccount *loggedInAccount;
}
@synthesize defaultUsername;
@synthesize loggedInAccount;

- (instancetype)init
{
    if (self = [super init]) {
        NSArray *storedAccounts = [[NSUserDefaults standardUserDefaults] arrayForKey:kAccountsPrefKey];
        
        accounts = [[NSMutableDictionary alloc] initWithCapacity: 5];
        passwordCache = [[NSMutableDictionary alloc] initWithCapacity: 5];
        
        for (id object in storedAccounts) {
            [self accountForUsername: object];
        }
        
        
        defaultUsername = [[[NSUserDefaults standardUserDefaults] stringForKey:kDefaultAccountNameKey] copy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountSwitched:)
                                                     name: XJAccountSwitchedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountSwitched:)
                                                     name:LJAccountDidLoginNotification
                                                   object:nil];
    }
    return self;
}

+ (XJAccountManager *)defaultManager
{
    if(!manager)
        manager = [[XJAccountManager alloc] init];
    return manager;
}

- (NSInteger)numberOfAccounts { return [[accounts allKeys] count]; }

- (NSDictionary *)accounts { return [NSDictionary dictionaryWithDictionary: accounts]; }

- (void)addAccountWithUsername: (NSString *)name password: (NSString *)password
{
    LJAccount *acct = [[LJAccount alloc] initWithUsername: name];
    accounts[name] = acct;

    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [accounts allKeys] forKey: kAccountsPrefKey];
    
    // Put password in KeyChain
	[[KeyChain defaultKeyChain] setGenericPassword: password 
										forService: [@"Xjournal: " stringByAppendingString: name] 
										   account:name];

    passwordCache[name] = password;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: XJAccountAddedNotification object: [self accountForUsername: name]];
}

- (void)removeAccountWithUsername: (NSString *)name
{
	LJAccount *acctToRelease = accounts[name];

	[[NSNotificationCenter defaultCenter] postNotificationName:XJAccountWillRemoveNotification object: acctToRelease];

    [accounts removeObjectForKey: name];
    [[KeyChain defaultKeyChain] removeGenericPasswordForService: [@"Xjournal: " stringByAppendingString: name] account: name];

    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [accounts allKeys] forKey: kAccountsPrefKey];

    if([name isEqualToString: defaultUsername]) {
        [self setDefaultUsername: [accounts allKeys][0]];
		NSAssert([[[self defaultAccount] username] isEqualToString:[self defaultUsername]], @"Account/username mismatch");
    }

	loggedInAccount = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:XJAccountRemovedNotification object:self];
}

- (LJAccount *)accountForUsername: (NSString *)username
{
    LJAccount *acct = accounts[username];
    if(!acct) {
        acct = [[LJAccount alloc] initWithUsername: username];
//#ifdef ENABLE_REACHABILITY_MONITORING
#if 0
        [acct.server enableReachabilityMonitoring];
#endif
        accounts[username] = acct;
    }
    return acct;
}

- (NSString *)passwordForUsername: (NSString *)username
{
    NSString *passwd = passwordCache[username];
    if(!passwd) {
        passwd = [[KeyChain defaultKeyChain] genericPasswordForService: [@"Xjournal: " stringByAppendingString: username] account: username];
        passwordCache[username] = passwd;
    }
    return passwd;
}

- (void)setPassword: (NSString *) passwd forUsername: (NSString *)username
{
    [[KeyChain defaultKeyChain] removeGenericPasswordForService: [@"Xjournal: " stringByAppendingString: username] account: username];
    [[KeyChain defaultKeyChain] setGenericPassword: passwd forService: [@"Xjournal: " stringByAppendingString: username] account:username];

    passwordCache[username] = passwd;
}

- (LJAccount *)defaultAccount
{
    if(defaultUsername)
        return [self accountForUsername: defaultUsername];
    else
        return nil;
}

- (void)logInAccount: (LJAccount *)theAccount
{
    [[theAccount server] setURL: [NSURL URLWithString:@"http://www.livejournal.com"]];
    
    @try {
        [theAccount loginWithPassword: [self passwordForUsername: [theAccount username]]];
        [theAccount downloadFriends];
    } @catch (NSException *localException) {
        NSLog(@"%@ - %@", [localException name], [localException reason]);
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Could not log in";
        alert.informativeText = localException.reason ?: @"Unknown reason";
        [alert runModal];
    }
}

- (void)setDefaultUsername: (NSString *)newDefault
{
    defaultUsername = [newDefault copy];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: defaultUsername forKey: kDefaultAccountNameKey];
	NSLog(@"Stored default username: %@", defaultUsername);
}

- (NSEnumerator *)menuItemEnumerator
{
    NSMutableArray *array = [NSMutableArray array];
    NSArray *keys = [[accounts allKeys] sortedArrayUsingSelector: @selector(compare:)];
    
    for (NSString* key in keys) {
        LJAccount *acct = [self accountForUsername: key];
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: [acct username] action: @selector(switchAccount:) keyEquivalent: @""];
        [item setTarget: nil];
        [item setRepresentedObject: acct];

        if(loggedInAccount && [[acct username] isEqualToString: [loggedInAccount username]])
            [item setState: NSOnState];
        else {
            // If there's no logged in account, set to the default account
            if(!loggedInAccount && [[acct username] isEqualToString: defaultUsername])
                [item setState: NSOnState];
        }
        [array addObject: item];
    }
    return [array objectEnumerator];
}

- (void)accountSwitched: (NSNotification *) note
{
    loggedInAccount = [note object];
}

@end
