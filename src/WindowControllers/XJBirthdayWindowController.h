//
//  XJBirthdayWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 24 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface XJBirthdayWindowController : NSWindowController {
    IBOutlet NSTableView *thisWeek, *thisMonth;
    NSArray *friendsThisWeek, *friendsThisMonth;
}

@end
