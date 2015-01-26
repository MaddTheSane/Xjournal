//
//  XJMetaLJGroup.m
//  Xjournal
//
//  Created by Fraser Speirs on 08/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJMetaLJGroup.h"

@implementation XJMetaLJGroup

- (id)initWithAccount:(LJAccount *)acct {
	self = [super init];
	if(self) {
		accountLock = [[NSLock alloc] init];
		lock = [[NSLock alloc] init];
		[self setAccount: acct];
		NSLog(@"Initied metagroup for account %@", [_account username]);

		[self setMemberArray: [NSMutableArray array]];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
					  ofObject:(id)object 
						change:(NSDictionary *)change
					   context:(void *)context
{
	NSLog(@"Got observation for path: %@\n%@", keyPath, [change description]);
	
	[self update];
}

- (void)update {
	NSLog(@"Updating XJMetaLJGroup");
	[self setMemberArray: [NSMutableArray array]];
	int i;
	NSArray *friends = [_account relationshipArray];
	[self willChangeValueForKey: @"memberArray"];
	for(i=0; i < [friends count]; i++) {
		[lock lock];
		[memberArray addObject: [friends objectAtIndex:i]];
		[lock unlock];
	}	
	[self didChangeValueForKey: @"memberArray"];
}

- (void)addFriend:(LJFriend *)amigo {
	[lock lock];
	[[self mutableArrayValueForKey:@"memberArray"] addObject: amigo];
	[lock unlock];
}

- (void)removeFriend: (LJFriend *)amigo {
	[lock lock];
	[[self mutableArrayValueForKey: @"memberArray"] removeObject: amigo];
	[lock unlock];
}

- (void)removeAllObjects {
	[lock lock];
	[[self mutableArrayValueForKey: @"memberArray"] removeAllObjects];
	[lock unlock];
}

- (void)setAccount: (LJAccount *)acc {
	NSLog(@"Setting account for metagroup");
	[accountLock lock];
	[_account removeObserver: self
				  forKeyPath: @"friendArray"];
	
	_account = acc;
	
	[_account addObserver: self
			   forKeyPath: @"friendArray"
				  options: (NSKeyValueObservingOptionNew)
				  context: NULL];
	[accountLock unlock];
	[self update];
}

// =========================================================== 
// - memberArray:
// =========================================================== 
- (NSMutableArray *)memberArray {
    return memberArray; 
}

// =========================================================== 
// - setMemberArray:
// =========================================================== 
- (void)setMemberArray:(NSMutableArray *)aMemberArray {
    if (memberArray != aMemberArray) {
        [aMemberArray retain];
        [memberArray release];
        memberArray = aMemberArray;
    }
}
@end
