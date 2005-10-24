//
//  XJSoftwareUpdatePrefClient.m
//  Xjournal
//
//  Created by Fraser Speirs on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "XJSoftwareUpdatePrefClient.h"
#import "XJPreferences.h"
#import "CCFSoftwareUpdate.h"

@implementation XJSoftwareUpdatePrefClient
- (IBAction)setValueForSender: (id) sender
{
    if([sender isEqualTo: autoButtons]) {
        [defaults setBool: ([[autoButtons selectedCell] tag] == 1) forKey: @"CCFSoftwareUpdateAutoCheck"];
    }
    else {
        [defaults setInteger: [sender tag] forKey: @"CCFSoftwareUpdateInterval"];
        [[CCFSoftwareUpdate sharedUpdateChecker] resetCheckTimer];
    }
}

- (IBAction)checkNow: (id)sender
{
    [[CCFSoftwareUpdate sharedUpdateChecker] runSoftwareUpdate: NO];
}

- (void)updateUI
{
    BOOL autoCheck = [defaults boolForKey:@"CCFSoftwareUpdateAutoCheck"];
    [autoButtons selectCellWithTag: autoCheck];
    [frequency selectItemAtIndex: [[frequency menu] indexOfItemWithTag:[defaults integerForKey: @"CCFSoftwareUpdateInterval"]]];
}
@end
