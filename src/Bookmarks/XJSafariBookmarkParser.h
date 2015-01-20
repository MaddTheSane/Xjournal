//
//  XJSafariBookmarkParser.h
//  Xjournal
//
//  Created by Fraser Speirs on Wed Jan 29 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

/*
 * This class can parse a Safari bookmark file into itself.
 * It can also act as an NSOutlineView data source.
 */
#import <Cocoa/Cocoa.h>
#import "XJBookmarkFolder.h"
#import "XJBookmarkItem.h"

@interface XJSafariBookmarkParser : NSObject {
    XJBookmarkFolder *rootFolder;
}

- (void)refreshFromDisk;
- (id)rootItem;
@end
