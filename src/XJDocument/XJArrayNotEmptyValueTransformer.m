//
//  XJArrayNotEmptyValueTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJArrayNotEmptyValueTransformer.h"


@implementation XJArrayNotEmptyValueTransformer
+ (Class)transformedValueClass { return [NSArray self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	return [NSNumber numberWithBool: ([value count] != 0)];
}
@end
