//
//  XJMarkupRemovalVT.m
//  Xjournal
//
//  Created by Fraser Speirs on 09/11/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XJMarkupRemovalVT.h"


@implementation XJMarkupRemovalVT
+ (Class)transformedValueClass {
    // class of the "output" objects, as returned by transformedValue:
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    // flag indicating whether transformation is read-only or not
	return NO;
}

- (id)transformedValue:(id)value {
	NSString *result = nil;
	
	// Remaining code from cocoa.karelia.com - see below.
	if (![value isEqualToString:@""])	// if empty string, don't do this!  You get junk.
	{
		// HACK -- IF SHORT LENGTH, USE MACROMAN -- FOR SOME REASON UNICODE FAILS FOR "" AND "-" AND "CNN" ...
		int encoding = ([value length] > 3) ? NSUnicodeStringEncoding : NSMacOSRomanStringEncoding;
		NSAttributedString *attrString;
		NSData *theData = [value dataUsingEncoding:encoding];
		if (nil != theData)	// this returned nil once; not sure why; so handle this case.
		{
			NSDictionary *encodingDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:encoding] forKey:@"CharacterEncoding"];
			attrString = [[NSAttributedString alloc] initWithHTML:theData documentAttributes:&encodingDict];
			result = [[[attrString string] retain] autorelease];	// keep only this
			[attrString release];	// don't do autorelease since this is so deep down.
		}
	}
	return result;
}

/*
 COPYRIGHT AND PERMISSION NOTICE 
 
 Copyright © 2003 Karelia Software, LLC. All rights reserved. 
 
 Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies. 
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 
 Except as contained in this notice, the name of a copyright holder shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization of the copyright holder.
 */
@end
