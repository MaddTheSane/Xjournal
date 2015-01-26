//
//  XJGroupToCheckfriendsAccessVT.h
//  Xjournal
//
//  Created by Fraser Speirs on 10/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>

@interface XJGroupToCheckfriendsAccessVT : NSValueTransformer {
	LJAccount *account;
}

- (LJAccount *)account;
- (void)setAccount:(LJAccount *)anAccount;
@end
