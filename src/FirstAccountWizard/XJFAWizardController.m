//
//  XJFAWizardController.m
//  Xjournal
//
//  Created by Fraser Speirs on 05/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJFAWizardController.h"
#import "XJAccountManager.h"
#import <LJKit/LJKit.h>

@implementation XJFAWizardController

- (id)init {
	self = [super init];
	if(self) {
		[self setServer: @"http://www.livejournal.com"];
		[self setPort: 80];
		[NSBundle loadNibNamed: @"FAWindow.nib" owner: self];
	}
	return self;
}

- (IBAction)commitWizard:(id)sender {
	[[self window] endEditingFor: nil];
	[[self window] orderOut: sender];
	
	// add account
	LJAccount *acct = [[LJAccount alloc] initWithUsername: [self username]];
	NSLog(@"Creating acct passwd: %@", [self password]); 
	[acct setPassword: [self password]];

	NSString *urlString = [NSString stringWithFormat: @"%@:%d", [self server], [self port]];
	[[acct server] setURL: [NSURL URLWithString: urlString]];
	
	[[XJAccountManager defaultManager] insertObject: acct inAccountsAtIndex: 0];
	[acct release];
	
	// Create a new document
	[[NSDocumentController sharedDocumentController] openUntitledDocumentOfType: @"Xjournal Entry" display: YES];
}

- (IBAction)cancelWizard:(id)sender {
	[[self window] orderOut: sender];
	
	[NSApp terminate: self];
}

- (IBAction)showWindow:(id)sender {
	[[self window] center];
	[super showWindow: sender];
}

//=========================================================== 
//  username 
//=========================================================== 
- (NSString *)username {
    return username; 
}
- (void)setUsername:(NSString *)anUsername {
    [anUsername retain];
    [username release];
    username = anUsername;
}

//=========================================================== 
//  password 
//=========================================================== 
- (NSString *)password {
    return password; 
}
- (void)setPassword:(NSString *)aPassword {
    [aPassword retain];
    [password release];
    password = aPassword;
	NSLog(@"FAWizard: %@", password);
}

//=========================================================== 
//  server 
//=========================================================== 
- (NSString *)server {
    return server; 
}
- (void)setServer:(NSString *)aServer {
    [aServer retain];
    [server release];
    server = aServer;
}

//=========================================================== 
//  port 
//=========================================================== 
- (int)port {
    return port;
}
- (void)setPort:(int)aPort {
    port = aPort;
}


//=========================================================== 
//  - dealloc:
//=========================================================== 
- (void)dealloc {
    [username release];
    [password release];
    [server release];
    [super dealloc];
}
@end
