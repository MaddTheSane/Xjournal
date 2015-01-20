//
//  XJBookmarkRoot.h
//  Xjournal
//
//  Created by Fraser Speirs on Tue Feb 04 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XJBookmarkRoot : NSObject
@property (copy) NSString *title;

- (instancetype)initWithTitle: (NSString *)newTitle NS_DESIGNATED_INITIALIZER;

- (NSComparisonResult)compare:(XJBookmarkRoot *)otherItem;
@end
