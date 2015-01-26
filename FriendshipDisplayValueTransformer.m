//
//  FriendshipDisplayValueTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 08/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "FriendshipDisplayValueTransformer.h"
#import <LJKit/LJKit.h>

@implementation FriendshipDisplayValueTransformer
+ (Class)transformedValueClass { return [LJFriend self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	switch([value intValue]) {
		case LJFriendshipIncoming:
			return @"Incoming";
		case LJFriendshipMutual:
			return @"Mutual";
		case LJFriendshipOutgoing:
			return @"Outgoing";
		default:
			return @"Unknown";
	}
}
@end
