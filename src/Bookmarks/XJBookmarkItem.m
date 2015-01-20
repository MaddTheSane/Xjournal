//
//  XJBookmarkItem.m
//  Xjournal
//
//  Created by Fraser Speirs on Mon Feb 03 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarkItem.h"


@implementation XJBookmarkItem
@synthesize webAddress = address;

+ (instancetype) bookmarkWithTitle: (NSString *)theTitle address: (NSURL *)url
{
    XJBookmarkItem *item = [[XJBookmarkItem alloc] initWithTitle: theTitle address: url];
    return item;
}

- (instancetype)initWithTitle:(NSString *)newTitle
{
    return [self initWithTitle:newTitle address:[NSURL URLWithString:@"http://www.google.com"]];
}

- (instancetype)initWithTitle:(NSString *)theTitle address: (NSURL *)url
{
    if (self = [super initWithTitle: theTitle]) {
        self.webAddress = url;
    }
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat: @"XJBookmarkItem: %@ (%@)", [self title], [address description]];
}

- (BOOL)hasChildren { return NO; }
@end
