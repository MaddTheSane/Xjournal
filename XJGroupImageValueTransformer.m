//
//  XJGroupImageValueTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 08/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJGroupImageValueTransformer.h"
#import <LJKit/LJKit.h>
#import "XJMetaLJGroup.h"

@implementation XJGroupImageValueTransformer
+ (Class)transformedValueClass { return [LJGroup self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	if([value isKindOfClass: [XJMetaLJGroup class]]) {
		return [NSImage imageNamed: @"userinfo"];
	}
	return [NSImage imageNamed: @"SmallFolder"];
}

@end
