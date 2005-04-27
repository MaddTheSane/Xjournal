//
//  XJFileSystemItem.m
//  GlossaryTest
//
//  Created by Fraser Speirs on Thu Aug 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "XJFileSystemItem.h"


@implementation XJFileSystemItem
- (id)initWithPath: (NSString *)thepath
{
    if([super init] == nil) 
        return nil;
    
    [self setPath: thepath];
    return self;
}

- (NSString *)path
{
    return path;
}

- (void)setPath: (NSString *)newPath
{
    [newPath retain];
    [path release];
    path = newPath;
}
@end
