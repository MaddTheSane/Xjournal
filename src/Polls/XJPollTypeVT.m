//
//  XJPollTypeVT.m
//  Xjournal
//
//  Created by Fraser Speirs on 06/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJPollTypeVT.h"
#import "LJPollMultipleOptionQuestion.h"
#import "LJPollQuestion.h"
#import "LJPollTextEntryQuestion.h"
#import "LJPollScaleQuestion.h"

@implementation XJPollTypeVT

+ (Class)transformedValueClass { return [LJPollQuestion self]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
	// Return the value as the kind declared in transformedValueClass
	NSLog(@"Transform %@", [value class]);
	if([value isKindOfClass: [LJPollMultipleOptionQuestion class]])
		return @"Multiple Choice";
	else if([value isKindOfClass: [LJPollTextEntryQuestion class]])
		return @"Text";
	
	return @"Scale";
}

/* Optionally implement this
- (id)reverseTransformedValue:(id)value {

}
*/

/* Paste this into some +(void)initialize somewhere

	[NSValueTransformer setValueTransformer: [[[XJPollTypeVT alloc] init] autorelease]
									forName: @"XJPollTypeVT"];

*/
@end
