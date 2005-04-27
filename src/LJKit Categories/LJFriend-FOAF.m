//
//  LJFriend-FOAF.m
//  Xjournal
//
//  Created by Fraser on Tue Feb 24 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "LJFriend-FOAF.h"

@implementation LJFriend (FOAF)
- (NSString *)foafXML
{
	NSLog(@"Downloading FOAF: %@", [[self foafURL] absoluteString]);
	NSData *data = [NSData dataWithContentsOfURL: [self foafURL]];
	NSString *foaf = [[NSString alloc] initWithData: data encoding:NSMacOSRomanStringEncoding];
	NSLog(foaf);
	return foaf;
}

- (NSString *)foafPropertyForDescriptor: (NSString *)descriptor
{
	return @"";
}
@end
