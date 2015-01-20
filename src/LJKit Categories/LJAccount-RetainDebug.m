//
//  LJAccount-RetainDebug.m
//  Xjournal
//
//  Created by Fraser Speirs on 01/08/2004.
//  Copyright 2004 Connected Flow. All rights reserved.
//

#import "LJAccount-RetainDebug.h"


@implementation LJAccount (RetainDebug)
- (id)retain {
	NSLog(@"Retaining LJAccount named %@ (RC = %d)", [self username], [self retainCount]+1);
	return [super retain];
}

- (id)autorelease {
	NSLog(@"About to autorelease LJAccount named %@ (RC = %d)", [self username], [self retainCount]);
	return [super autorelease];
}

- (void)release {
	NSLog(@"Releaseing LJAccount named %@ (RC = %d)", [self username], [self retainCount]-1);
	[super release];
}
@end
