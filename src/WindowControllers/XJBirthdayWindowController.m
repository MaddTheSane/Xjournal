//
//  XJBirthdayWindowController.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 24 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJBirthdayWindowController.h"
#import "XJAccountManager.h"
#import "LJAccount-BirthdayExtensions.h"

@implementation XJBirthdayWindowController
- (id)init
{
    if([super initWithWindowNibName:@"BirthdaysWindow"] == nil) 
        return nil;
            
    friendsThisWeek = [[[[XJAccountManager defaultManager] defaultAccount] friendsWithBirthdaysThisWeek] retain];
    friendsThisMonth = [[[[XJAccountManager defaultManager] defaultAccount] friendsWithBirthdaysThisMonth] retain];
    [thisWeek reloadData];
    [thisMonth reloadData];
    
    return self;
}

- (void)windowDidLoad
{
    // Configure the icon column to display images
    NSTableColumn *tc = [thisWeek tableColumnWithIdentifier:@"icon"];
    id cell = [[NSImageCell alloc] init];
    [cell setImageScaling:NSScaleNone];
    [tc setDataCell:cell];

    tc = [thisMonth tableColumnWithIdentifier:@"icon"];
    [tc setDataCell: cell];
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if([aTableView isEqualTo: thisWeek])
        return [friendsThisWeek count];
    else
        return [friendsThisMonth count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([[aTableColumn identifier] isEqualToString: @"icon"])
        return [NSImage imageNamed: @"userinfo"];
    else if([[aTableColumn identifier] isEqualToString: @"username"]) {
        if([aTableView isEqualTo: thisWeek])
            return [[friendsThisWeek objectAtIndex: rowIndex] username];
        else
            return [[friendsThisMonth objectAtIndex: rowIndex] username];
    }    
    else {
        if([aTableView isEqualTo: thisWeek])
            return [[[friendsThisWeek objectAtIndex: rowIndex] birthDate] description];
        else
            return [[[friendsThisMonth objectAtIndex: rowIndex] birthDate] description]; 
    }
}


@end
