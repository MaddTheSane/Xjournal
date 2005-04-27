//
//  XJBookmarkRoot.m
//  Xjournal
//
//  Created by Fraser Speirs on Tue Feb 04 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarkRoot.h"


@implementation XJBookmarkRoot
- (id)initWithTitle: (NSString *)newTitle
{
    if(self == [super init]) {
        [self setTitle: newTitle];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [title release];
    [super dealloc];
}

- (NSString *)title { return title; }

- (void)setTitle: (NSString *)newTitle
{
    [title release];
    title = [[NSString stringWithString: newTitle] retain];
}


- (NSComparisonResult)compare:(XJBookmarkRoot *)otherItem
{
    return [title compare: [otherItem title]];
}

@end
