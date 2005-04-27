//
//  XJSoftwareUpdate.m
//  Xjournal
//
//  Created by Fraser Speirs on Tue Mar 18 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJSoftwareUpdate.h"
#import "XJPreferences.h"

#import <OmniFoundation/OmniFoundation.h>

#define DAILY_CHECK_INTERVAL 24
#define WEEKLY_CHECK_INTERVAL 168
#define MONTHLY_CHECK_INTERVAL 672

static NSString *OSUCheckEnabled = @"AutomaticSoftwareUpdateCheckEnabled";
static NSString *OSUCheckFrequencyKey = @"OSUCheckInterval";

@implementation XJSoftwareUpdate
- (IBAction)setValueForSender: (id) sender
{
    if([sender isEqualTo: enableMatrix]) {
        [PREFS setBool: [[enableMatrix selectedCell] tag] forKey: OSUCheckEnabled];
    }
    else if([sender isEqualTo: frequencyPopup]) {
        int selectedOption = [[frequencyPopup selectedItem] tag];

        if(selectedOption == 0)
            [PREFS setInteger: DAILY_CHECK_INTERVAL forKey: OSUCheckFrequencyKey];
        else if(selectedOption == 1)
            [PREFS setInteger: WEEKLY_CHECK_INTERVAL forKey: OSUCheckFrequencyKey];
        else
            [PREFS setInteger: MONTHLY_CHECK_INTERVAL forKey: OSUCheckFrequencyKey];
    }
}

- (void)updateUI
{
    int checkInterval = [PREFS integerForKey: OSUCheckFrequencyKey];
    if(checkInterval == DAILY_CHECK_INTERVAL)
        [frequencyPopup selectItemWithTag: 0];
    else if(checkInterval == WEEKLY_CHECK_INTERVAL)
        [frequencyPopup selectItemWithTag: 1];
    else
        [frequencyPopup selectItemWithTag: 2];
    
    [enableMatrix selectCellWithTag: [PREFS boolForKey: OSUCheckEnabled]];
}
@end
