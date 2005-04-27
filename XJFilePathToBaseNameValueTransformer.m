//
//  XJFilePathToBaseNameValueTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJFilePathToBaseNameValueTransformer.h"


@implementation XJFilePathToBaseNameValueTransformer
+ (Class)transformedValueClass { return [NSString self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	return [[[value lastPathComponent] componentsSeparatedByString: @"."] objectAtIndex: 0];
}

@end
