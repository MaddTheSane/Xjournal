//
//  XJHTMLPreviewTitleTransformer.m
//  Xjournal
//
//  Created by Fraser Speirs on 18/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJHTMLPreviewTitleTransformer.h"

@implementation XJHTMLPreviewTitleTransformer

+ (Class)transformedValueClass { return [NSString self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	// Return the value as the kind declared in transformedValueClass
	return [NSString stringWithFormat: @"%@ [HTML Preview]", value];
}

/* Optionally implement this
- (id)reverseTransformedValue:(id)value {

}
*/

/* Paste this into some +(void)initialize somewhere

	[NSValueTransformer setValueTransformer: [[[XJHTMLPreviewTitleTransformer alloc] init] autorelease]
									forName: @"XJHTMLPreviewTitleTransformer"];

*/
@end
