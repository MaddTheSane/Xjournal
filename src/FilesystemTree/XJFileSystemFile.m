//
//  XJFileSystemFile.m
//  GlossaryTest
//
//  Created by Fraser Speirs on Thu Aug 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "XJFileSystemFile.h"


@implementation XJFileSystemFile
- (id)initWithPath: (NSString *)thePath
{
    if([super initWithPath:thePath] == nil)
        return nil;
    return self;
}
@end
