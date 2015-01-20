//
//  XJBookmarkFolder.m
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarkFolder.h"


@implementation XJBookmarkFolder

+ (XJBookmarkFolder *)folderWithTitle: (NSString *)aTitle
{
    XJBookmarkFolder *folder = [[XJBookmarkFolder alloc] initWithTitle: aTitle];
    return [folder autorelease];
}

- (id)initWithTitle:(NSString *)aTitle
{
    if(self == [super initWithTitle: aTitle]) {
        children = [[NSMutableArray arrayWithCapacity: 100] retain];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [children release];
    [super dealloc];
}

- (BOOL)hasChildren
{
    return [children count] > 0;
}

- (int)numberOfChildren
{
    return [children count];
}

- (XJBookmarkRoot *)childAtIndex:(int)idx
{
    return [children objectAtIndex: idx];
}

- (void)addChild: (XJBookmarkRoot *)newChild  // Retains the child
{
    [children addObject: newChild];
    //[children sortUsingSelector: @selector(compare:)];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"XJBookmarkFolder %@ (%u)", [self title], [self numberOfChildren]];
}
@end
