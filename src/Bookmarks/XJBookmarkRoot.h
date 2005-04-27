//
//  XJBookmarkRoot.h
//  Xjournal
//
//  Created by Fraser Speirs on Tue Feb 04 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XJBookmarkRoot : NSObject {
    NSString *title;
}

- (id)initWithTitle: (NSString *)newTitle;
- (NSString *)title;
- (void)setTitle: (NSString *)newTitle;
- (NSComparisonResult)compare:(XJBookmarkRoot *)otherItem;
@end
