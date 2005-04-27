//
//  XJFileSystemFolder.m
//  GlossaryTest
//
//  Created by Fraser Speirs on Thu Aug 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "XJFileSystemFolder.h"

@interface XJFileSystemFolder (PrivateAPI)
- (void)lazilyInstantiateChildren;
@end

@implementation XJFileSystemFolder
- (id)initWithPath: (NSString *)thepath
{
    if([super initWithPath: thepath] == nil) 
        return nil;
    return self;
}

- (void)dealloc
{
    [children release];
    [super dealloc];
}

- (int)numberOfChildren
{
    if(!children)
        [self lazilyInstantiateChildren];
    return [children count];
}

- (XJFileSystemItem *)childAtIndex: (int)idx
{
    if(!children)
        [self lazilyInstantiateChildren];
    
    return [children objectAtIndex: idx];
}

- (void)addChild: (XJFileSystemItem *)newchild
{
    [children addObject: newchild];
}

@end

@implementation XJFileSystemFolder (PrivateAPI)
- (void)lazilyInstantiateChildren
{
    children = [[NSMutableArray arrayWithCapacity: 10] retain];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *contentsAtPath = [manager directoryContentsAtPath:[self path]];
    
    NSEnumerator *enumerator = [contentsAtPath objectEnumerator];
    NSString *item;
    while(item = [enumerator nextObject]) {
        if(![item hasPrefix: @"."]) {
            BOOL isDir;
            NSString *fullPath = [NSString stringWithFormat: @"%@/%@", [self path], item];
            [manager fileExistsAtPath: fullPath isDirectory: &isDir];
            
            XJFileSystemItem *newChild;
            if(isDir) {
                newChild = [[XJFileSystemFolder alloc] initWithPath: fullPath];
            }
            else {
                newChild = [[XJFileSystemFile alloc] initWithPath: fullPath];
            }
            [self addChild:newChild];
            [newChild release];
        }
    }
}

// Drag and drop type stuff

@end