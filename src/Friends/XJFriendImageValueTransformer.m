//
//  XJFriendImageValueTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 08/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJFriendImageValueTransformer.h"


@implementation XJFriendImageValueTransformer
+ (Class)transformedValueClass { return [LJFriend self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	if([[value accountType] isEqualToString: @"community"]) {
		return [NSImage imageNamed: @"communitysmall"];
	}
	return [NSImage imageNamed: @"userinfo"];
}
@end
