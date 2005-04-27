//
//  XJSUController.m
//  XJSoftwareUpdate
//
//  Created by Fraser Speirs on Wed Apr 16 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJSUController.h"
#import <OmniFoundation/OmniFoundation.h>

@interface XJSUController(Private)
- (void)_checkForNewVersion;
- (void)_runNewVersionDialog:(id)sender;
@end

static XJSUController *controller;

@implementation XJSUController
+ sharedController
{
    if(!controller) {
        controller = [[XJSUController alloc] init];
        [[OFSoftwareUpdateChecker sharedUpdateChecker] setTarget: self];
        [[OFSoftwareUpdateChecker sharedUpdateChecker] setAction: @selector(newVersionAvailable:)];
    }
    return controller;
}

+ (void)checkSynchronouslyWithUIAttachedToWindow: (id)sender
{
    [[self sharedController] _checkForNewVersion];
}

+ (void)newVersionAvailable: (NSDictionary *)versionInfo
{
    [[self sharedController] _runNewVersionDialog: versionInfo];
}

- (void)downloadNow: (NSString *)downloadURL
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: downloadURL]];
}

- (IBAction)showMoreInfo: (NSString *)urlPage
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: urlPage]];
}
@end

@implementation XJSUController (Private)
- (void)_checkForNewVersion
{
    BOOL isNewVersion = [[OFSoftwareUpdateChecker sharedUpdateChecker] checkSynchronously];

    if(!isNewVersion) {
        NSRunInformationalAlertPanel(NSLocalizedString(@"No new version", @""),
                                     NSLocalizedString(@"There is no new version of Xjournal available", @""),
                                     nil, nil, nil);
    }
    
}

- (void)_runNewVersionDialog:(NSDictionary *)versionInfo
{
    int result = NSRunInformationalAlertPanel(NSLocalizedString(@"There is a new version of Xjournal available", @""),
                                              [NSString stringWithFormat: NSLocalizedString(@"The new version of Xjournal is %@.  Click 'Download' to get the new version now.  Click 'More Info' to go to the Xjournal website.", @""), [versionInfo objectForKey: @"displayVersion"]],
                                              NSLocalizedString(@"Download Now", @""),
                                              NSLocalizedString(@"More Info", @""),
                                              NSLocalizedString(@"Cancel", @""));

    switch(result) {
        case NSAlertDefaultReturn:
            [self downloadNow: [versionInfo objectForKey: @"directDownload"]];
            break;
        case NSAlertAlternateReturn:
            [self showMoreInfo: [versionInfo objectForKey: @"downloadPage"]];
            break;
        case NSAlertOtherReturn:
            break;
    }
}
@end