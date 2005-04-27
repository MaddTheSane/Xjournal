//
//  XJFAWizardController.h
//  Xjournal
//
//  Created by Fraser Speirs on 05/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJFAWizardController : NSWindowController {
	NSString *username;
	NSString *password;
	NSString *server;
	int port;
}

- (IBAction)commitWizard:(id)sender;
- (IBAction)cancelWizard:(id)sender;

- (NSString *)username;
- (void)setUsername:(NSString *)anUsername;
- (NSString *)password;
- (void)setPassword:(NSString *)aPassword;
- (NSString *)server;
- (void)setServer:(NSString *)aServer;
- (int)port;
- (void)setPort:(int)aPort;

@end
