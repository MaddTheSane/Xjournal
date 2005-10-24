//
//  XJFileSystemItem.h
//  GlossaryTest
//
//  Created by Fraser Speirs on Thu Aug 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XJFileSystemItem : NSObject {
    NSString *path;
}

- (id)initWithPath: (NSString *)thepath;

- (NSString *)path;
- (void)setPath: (NSString *)newPath;

@end
