//
//  XJFontNameToDisplayVT.m
//  Xjournal
//
//  Created by Fraser Speirs on 20/11/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XJFontNameToDisplayVT.h"


@implementation XJFontNameToDisplayVT
+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)aValue
{
    NSFont *font = [NSFont fontWithName:aValue size:12];
	return [font displayName];
}
@end
