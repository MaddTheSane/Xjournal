//
//  XJBookmarkItem.h
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJBookmarkRoot.h"

@interface XJBookmarkItem : XJBookmarkRoot
@property (strong) NSURL* webAddress;

+ (instancetype) bookmarkWithTitle: (NSString *)theTitle address: (NSURL *)url;
- (instancetype)initWithTitle:(NSString *)theTitle address: (NSURL *)url NS_DESIGNATED_INITIALIZER;

@property (readonly) BOOL hasChildren;
@end
