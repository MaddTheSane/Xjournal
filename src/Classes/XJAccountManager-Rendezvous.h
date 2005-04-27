//
//  XJAccountManager-Rendezvous.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 10 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJAccountManager.h"

@interface XJAccountManager (Rendezvous)
- (void)publishNetService;
- (void)unpublishNetService;
- (void)beginBrowsing;
- (void)endBrowsing;

- (NSData *)rendezvousDataRepresentation;
- (void)initialiseRendezvousRepresentation: (NSData *)data serviceName: (NSString *)sName;
- (NSArray *)discoveredAccounts;
- (void)removeDiscoveredAccountsFromService: (NSString *)service;

- (void)handleIPAddressChange;
- (void)destroyListeningSocket;
- (void)createListeningSocket;
@end
