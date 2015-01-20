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

+ (instancetype)folderWithTitle: (NSString *)aTitle;
- (instancetype)initWithTitle:(NSString *)aTitle NS_DESIGNATED_INITIALIZER;

@property (readonly) BOOL hasChildren;
@property (readonly) NSInteger numberOfChildren;
- (XJBookmarkRoot *)childAtIndex:(NSInteger)idx;

- (void)addChild: (XJBookmarkRoot *)newChild;  // Retains the child
@end
