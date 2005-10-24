//
//  XJFileSystemFolder.h
//  GlossaryTest
//
//  Created by Fraser Speirs on Thu Aug 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XJFileSystemItem.h"
#import "XJFileSystemFile.h"

@interface XJFileSystemFolder : XJFileSystemItem {
    NSMutableArray *children;
}

- (id)initWithPath: (NSString *)thepath;

- (int)numberOfChildren;
- (XJFileSystemItem *)childAtIndex: (int)idx;

- (void)addChild: (XJFileSystemItem *)newchild;
@end
