//
//  XJSUPreferences.m
//  XJSoftwareUpdate
//
//  Created by Fraser Speirs on Wed Apr 16 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "XJSUPreferences.h"

#define DAILY_CHECK_INTERVAL 24
#define WEEKLY_CHECK_INTERVAL 168
#define MONTHLY_CHECK_INTERVAL 672

static NSString *OSUCheckEnabled = @"AutomaticSoftwareUpdateCheckEnabled";
static NSString *OSUCheckFrequencyKey = @"OSUCheckInterval";

@implementation XJSUPreferences
- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");
}

- (IBAction) checkNow: (id)sender
{
    [NSApp checkForNewVersion: sender];
}

- (IBAction)setValueForSender: (id) sender
{
    NSLog(@"setValueForSender");
    if([sender isEqualTo: enableMatrix]) {
        [defaults setBool: [[enableMatrix selectedCell] tag] forKey: OSUCheckEnabled];
    }
    else if([sender isEqualTo: frequencyPopup]) {
        int selectedOption = [[frequencyPopup selectedItem] tag];

        if(selectedOption == 0)
            [defaults setInteger: DAILY_CHECK_INTERVAL forKey: OSUCheckFrequencyKey];
        else if(selectedOption == 1)
            [defaults setInteger: WEEKLY_CHECK_INTERVAL forKey: OSUCheckFrequencyKey];
        else
            [defaults setInteger: MONTHLY_CHECK_INTERVAL forKey: OSUCheckFrequencyKey];
    }
}

- (void)updateUI
{
    NSLog(@"updateUI");
    int checkInterval = [defaults integerForKey: OSUCheckFrequencyKey];
    if(checkInterval == DAILY_CHECK_INTERVAL)
        [frequencyPopup selectItemWithTag: 0];
    else if(checkInterval == WEEKLY_CHECK_INTERVAL)
        [frequencyPopup selectItemWithTag: 1];
    else
        [frequencyPopup selectItemWithTag: 2];

    [enableMatrix selectCellWithTag: [defaults boolForKey: OSUCheckEnabled]];
}

@end
