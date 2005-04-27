//
//  XJKeywordToImageValueTransformer.h
//  Xjournal
//
//  Created by Fraser Speirs on 18/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>

@interface XJKeywordToImageValueTransformer : NSValueTransformer {
	LJAccount *account;
	NSMutableDictionary *cache;
}

- (LJAccount *)account;
- (void)setAccount:(LJAccount *)anAccount;

@end
