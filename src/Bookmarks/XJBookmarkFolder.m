//
//  XJBookmarkFolder.m
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarkFolder.h"


@implementation XJBookmarkFolder

+ (instancetype)folderWithTitle: (NSString *)aTitle
{
    XJBookmarkFolder *folder = [[XJBookmarkFolder alloc] initWithTitle: aTitle];
    return folder;
}

- (instancetype)initWithTitle:(NSString *)aTitle
{
    if (self = [super initWithTitle: aTitle]) {
        children = [[NSMutableArray alloc] initWithCapacity: 100];
    }
    return self;
}


- (BOOL)hasChildren
{
    return [children count] > 0;
}

- (NSInteger)numberOfChildren
{
    return [children count];
}

- (XJBookmarkRoot *)childAtIndex:(NSInteger)idx
{
    return children[idx];
}

- (void)addChild: (XJBookmarkRoot *)newChild  // Retains the child
{
    [children addObject: newChild];
    //[children sortUsingSelector: @selector(compare:)];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"XJBookmarkFolder %@ (%ld)", [self title], (long)[self numberOfChildren]];
}
@end
