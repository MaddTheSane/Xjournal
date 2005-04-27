//
//  AccountManager.h
//  Xjournal
//
//  Created by Fraser Speirs on Sun Apr 06 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

/*
 The XJaccountManager manages a mutable array of LJAccount objects.
 
 It's a singleton, and the idea is that each XJDocument class keeps 
 an iVar reference to it and looks in here for accounts to associate 
 with journals and entries.
 */

@interface XJAccountManager : NSObject {
    NSMutableDictionary *passwordCache;
	NSMutableArray *accounts;
	NSMutableDictionary *cfSessions;
	
	NSTimer *loginCheckTimer;
	
	LJAccount *defaultAccount;
}

+ (XJAccountManager *)defaultManager;

- (NSMutableDictionary *)passwordCache;
- (void)setPasswordCache:(NSMutableDictionary *)aPasswordCache;

- (NSMutableArray *)accounts;
- (void)setAccounts:(NSMutableArray *)anAccounts;
	///////  accounts  ///////

- (unsigned int)countOfAccounts;
- (id)objectInAccountsAtIndex:(unsigned int)index;
- (void)insertObject:(id)anObject inAccountsAtIndex:(unsigned int)index;
- (void)removeObjectFromAccountsAtIndex:(unsigned int)index;
- (void)replaceObjectInAccountsAtIndex:(unsigned int)index withObject:(id)anObject;

- (NSMutableDictionary *)cfSessions;
- (void)setCfSessions:(NSMutableDictionary *)aCfSessions;

- (void)setAccount: (LJAccount *)account checksFriends: (BOOL)flag startChecking:(BOOL)shouldStart;
- (BOOL)accountChecksFriends: (LJAccount *)acc;
- (LJCheckFriendsSession *)cfSessionForAccount: (LJAccount *)acct;

- (LJAccount *)defaultAccount;
- (void)setDefaultAccount:(LJAccount *)aDefaultAccount;

- (LJAccount *)accountWithUsername: (NSString *)accName;
@end
