//
//  XJDonationWindowController.m
//  Xjournal
//
//  Created by Fraser on Tue Feb 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "XJDonationWindowController.h"
#import "XJPreferences.h"

@implementation XJDonationWindowController
- (id)init {
	if(self == [super init]) {
		[NSBundle loadNibNamed:@"Donation" owner:self];
		[self showWindow:self];
	}
	return self;
}

- (void)windowWillClose: (NSNotification *)note {
	[XJPreferences setShowDonationWindow: NO];
}
@end
