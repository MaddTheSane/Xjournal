//
//  XJGroupToCheckfriendsAccessVT.m
//  Xjournal
//
//  Created by Fraser Speirs on 10/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJGroupToCheckfriendsAccessVT.h"
#import "XJAccountManager.h"

@implementation XJGroupToCheckfriendsAccessVT
+ (Class)transformedValueClass { return [NSNumber self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	if([self account]) {
		XJAccountManager *manager = [XJAccountManager defaultManager];
		LJCheckFriendsSession *cfSession = [manager cfSessionForAccount: [self account]];
		
		return [NSNumber numberWithBool: [[cfSession checkGroupSet] containsObject: value]];
	}
	else {
		return [NSNumber numberWithBool: NO];
	}
}

//=========================================================== 
// - account:
//=========================================================== 
- (LJAccount *)account {
    return account; 
}

//=========================================================== 
// - setAccount:
//=========================================================== 
- (void)setAccount:(LJAccount *)anAccount {
    account = anAccount;
}
@end
