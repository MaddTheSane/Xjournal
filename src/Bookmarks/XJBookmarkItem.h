//
//  XJBookmarkItem.h
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJBookmarkRoot.h"

@interface XJBookmarkItem : XJBookmarkRoot {
    NSURL *address;
}

+ (XJBookmarkItem *) bookmarkWithTitle: (NSString *)theTitle address: (NSURL *)url;
- (id)initWithTitle:(NSString *)theTitle address: (NSURL *)url;

- (NSURL *)webAddress;
- (void)setWebAddress: (NSURL *)newURL;

- (BOOL)hasChildren;
@end
