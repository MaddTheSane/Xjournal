//
//  XJBookmarkItem.m
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarkItem.h"


@implementation XJBookmarkItem
+ (XJBookmarkItem *) bookmarkWithTitle: (NSString *)theTitle address: (NSURL *)url
{
    XJBookmarkItem *item = [[XJBookmarkItem alloc] initWithTitle: theTitle address: url];
    return [item autorelease];
}

- (id)initWithTitle:(NSString *)theTitle address: (NSURL *)url
{
    if(self == [super initWithTitle: theTitle]) {
        [self setWebAddress: url];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [address release];
    [super dealloc];
}

- (NSURL *)webAddress { return address; }

- (void)setWebAddress: (NSURL *)newURL
{
    address = [newURL copy];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"XJBookmarkItem: %@ (%@)", [self title], [address description]];
}

- (BOOL)hasChildren { return NO; }
@end
