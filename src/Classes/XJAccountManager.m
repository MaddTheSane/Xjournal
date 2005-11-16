//
//  AccountManager.m
//  Xjournal
//
//  Created by Fraser Speirs on Sun Apr 06 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJAccountManager.h"
#import "XJPreferences.h"
#import "XJKeyChain.h"
#import "NetworkConfig.h"

#define kAccountsPrefKey @"Accounts"
#define kDefaultAccountNameKey @"DefaultAccount"

static XJAccountManager *manager;

@implementation XJAccountManager

- (id)init
{
    if([super init] == nil)
        return nil;

    NSArray *storedAccounts = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kAccountsPrefKey];

    accounts = [[NSMutableDictionary dictionaryWithCapacity: 5] retain];
    passwordCache = [[NSMutableDictionary dictionaryWithCapacity: 5] retain];
    
    NSEnumerator *enumerator = [storedAccounts objectEnumerator];
    id object;
    
    while (object = [enumerator nextObject]) {
        [self accountForUsername: object];
    }
    
    
    defaultUsername = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: kDefaultAccountNameKey] copy];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountSwitched:)
                                                 name: XJAccountSwitchedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountSwitched:)
                                                 name:LJAccountDidLoginNotification
                                               object:nil];       
    return self;
}

+ (XJAccountManager *)defaultManager
{
    if(!manager)
        manager = [[XJAccountManager alloc] init];
    return manager;
}

- (int)numberOfAccounts { return [[accounts allKeys] count]; }

- (NSDictionary *)accounts { return accounts; }

- (void)addAccountWithUsername: (NSString *)name password: (NSString *)password
{
    LJAccount *acct = [[LJAccount alloc] initWithUsername: name];
    [accounts setObject: acct forKey: name];
    [acct release];

    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [accounts allKeys] forKey: kAccountsPrefKey];
    
    // Put password in XJKeyChain
	[[XJKeyChain defaultKeyChain] setGenericPassword: password 
										forService: [@"Xjournal: " stringByAppendingString: name] 
										   account:name];

    [passwordCache setObject: password forKey: name];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: XJAccountAddedNotification object: [self accountForUsername: name]];
}

- (void)removeAccountWithUsername: (NSString *)name
{
	LJAccount *acctToRelease = [accounts objectForKey: name];

	[[NSNotificationCenter defaultCenter] postNotificationName:XJAccountWillRemoveNotification object: acctToRelease];

    [accounts removeObjectForKey: name];
    [[XJKeyChain defaultKeyChain] removeGenericPasswordForService: [@"Xjournal: " stringByAppendingString: name] account: name];

    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [accounts allKeys] forKey: kAccountsPrefKey];

    if([name isEqualToString: defaultUsername]) {
        [self setDefaultUsername: [[accounts allKeys] objectAtIndex: 0]];
		NSAssert([[[self defaultAccount] username] isEqualToString:[self defaultUsername]], @"Account/username mismatch");
    }

	loggedInAccount = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:XJAccountRemovedNotification object:self];
}

- (LJAccount *)accountForUsername: (NSString *)username
{
    LJAccount *acct = [accounts objectForKey: username];
    if(!acct) {
        acct = [[LJAccount alloc] initWithUsername: username];
        [accounts setObject: acct forKey: username];
        [acct release];
    }
    return acct;
}

- (NSString *)passwordForUsername: (NSString *)username
{
    NSString *passwd = [passwordCache objectForKey: username];
    if(!passwd) {
        passwd = [[XJKeyChain defaultKeyChain] genericPasswordForService: [@"Xjournal: " stringByAppendingString: username] account: username];
        [passwordCache setObject: passwd forKey: username];
    }
    return passwd;
}

- (void)setPassword: (NSString *) passwd forUsername: (NSString *)username
{
    [[XJKeyChain defaultKeyChain] removeGenericPasswordForService: [@"Xjournal: " stringByAppendingString: username] account: username];
    [[XJKeyChain defaultKeyChain] setGenericPassword: passwd forService: [@"Xjournal: " stringByAppendingString: username] account:username];

    [passwordCache setObject: passwd forKey: username];
}

- (LJAccount *)defaultAccount
{
    if(defaultUsername)
        return [self accountForUsername: defaultUsername];
    else
        return nil;
}

- (LJAccount *)loggedInAccount
{
    return loggedInAccount;
}

- (void)logInAccount: (LJAccount *)theAccount
{

		[[theAccount server] setURL: [NSURL URLWithString:@"http://www.livejournal.com"]];

	NS_DURING
		[theAccount loginWithPassword: [self passwordForUsername: [theAccount username]]];
        [theAccount downloadFriends];
	NS_HANDLER
		NSLog(@"%@ - %@", [localException name], [localException reason]);
		NSRunAlertPanel(@"Could not log in",
						[localException reason],
						@"OK",nil,nil);
	NS_ENDHANDLER
}

- (NSString *)defaultUsername { return defaultUsername; }

- (void)setDefaultUsername: (NSString *)newDefault
{
    [newDefault retain];
    [defaultUsername release];
    defaultUsername = newDefault;
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: defaultUsername forKey: kDefaultAccountNameKey];
	NSLog(@"Stored default username: %@", defaultUsername);
}

- (NSEnumerator *)menuItemEnumerator
{
    NSMutableArray *array = [NSMutableArray array];
    NSArray *keys = [[accounts allKeys] sortedArrayUsingSelector: @selector(compare:)];
    
    int i;
    for(i=0; i < [keys count]; i++) {
        LJAccount *acct = [self accountForUsername: [keys objectAtIndex:i]];
        
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
