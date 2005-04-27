//
//  XJMetaLJGroup.h
//  Xjournal
//
//  Created by Fraser Speirs on 08/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>

@interface XJMetaLJGroup : LJGroup {
	NSMutableArray *memberArray;
	BOOL needsUpdate;
	
	NSLock *lock;
	NSLock *accountLock;
}

- (void)removeAllObjects;

- (void)setAccount: (LJAccount *)acc;
- (void)update;
- (NSMutableArray *)memberArray;
- (void)setMemberArray:(NSMutableArray *)aMemberArray;

@end
