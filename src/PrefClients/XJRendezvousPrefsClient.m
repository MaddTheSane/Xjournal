//
//  XJRendezvousPrefsClient.m
//  Xjournal
//
//  Created by Fraser Speirs on Mon Apr 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJRendezvousPrefsClient.h"
#import "XJPreferences.h"
#import "XJAccountManager.h"
#import "XJAccountManager-Rendezvous.h"

@implementation XJRendezvousPrefsClient
- (IBAction)setValueForSender: (id) sender
{
    [defaults setBool: [sender state] forKey: SHARE_RENDEZVOUS];

    if([sender state])
        NSLog(@"Not publishing because of crashing bug");
        //[[XJAccountManager defaultManager] publishNetService]; // XXX Disabled due to mobility crasher
    else
        [[XJAccountManager defaultManager] unpublishNetService];
}

- (void)updateUI
{
    [shareData setState: [defaults boolForKey: SHARE_RENDEZVOUS]];
}
@end
