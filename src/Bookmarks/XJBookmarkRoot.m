//
//  XJBookmarkRoot.m
//  Xjournal
//
//  Created by Fraser Speirs on Tue Feb 04 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJBookmarkRoot.h"


@implementation XJBookmarkRoot
@synthesize title;

- (instancetype)initWithTitle: (NSString *)newTitle
{
    if (self = [super init]) {
        self.title = newTitle;
    }
    return self;
}

- (NSComparisonResult)compare:(XJBookmarkRoot *)otherItem
{
    return [title compare: [otherItem title]];
}

@end
