//
//  XJBookmarkFolder.h
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJBookmarkRoot.h"

@interface XJBookmarkFolder : XJBookmarkRoot {
    NSMutableArray *children;
}

+ (XJBookmarkFolder *)folderWithTitle: (NSString *)aTitle;
- (id)initWithTitle:(NSString *)aTitle;

- (BOOL)hasChildren;
- (int)numberOfChildren;
- (XJBookmarkRoot *)childAtIndex:(int)idx;

- (void)addChild: (XJBookmarkRoot *)newChild;  // Retains the child
@end
