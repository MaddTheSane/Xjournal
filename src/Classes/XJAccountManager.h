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

#define XJRendezvousAccountsUpdated @"XJRendezvousAccountsUpdated"

@interface XJAccountManager : NSObject

+ (XJAccountManager *)defaultManager;

@property (readonly) NSInteger numberOfAccounts;
@property (readonly, copy) NSDictionary *accounts;

- (void)addAccountWithUsername: (NSString *)name password: (NSString *)password;
- (void)removeAccountWithUsername: (NSString *)name;

- (void)setPassword: (NSString *) passwd forUsername: (NSString *)username;

- (LJAccount *)accountForUsername: (NSString *)username;
- (NSString *)passwordForUsername: (NSString *)username;

- (LJAccount *)defaultAccount;
@property (nonatomic, copy) NSString *defaultUsername;

@property (nonatomic, strong, setter=logInAccount:) LJAccount *loggedInAccount;
- (void)logInAccount: (LJAccount *)theAccount;

@property (readonly, strong) NSEnumerator *menuItemEnumerator;
@end
