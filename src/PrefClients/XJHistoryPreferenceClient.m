//
//  XJHistoryPreferenceClient.m
//  Xjournal
//
//  Created by Fraser Speirs on Fri Jun 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "XJHistoryPreferenceClient.h"
#import "XJPreferences.h"
#import <WebKit/WebKit.h>

@implementation XJHistoryPreferenceClient
- (void)awakeFromNib
{}

- (void)updateUI
{
    //WebPreferences *wPrefs = [[WebPreferences alloc] initWithIdentifier: XJ_HISTORY_PREF_IDENT];
    BOOL openInXjournal = [XJPreferences openHistoryLinksInXjournal];
    
    if(openInXjournal)
        [linkPreference selectCellWithTag: 0];
    else
        [linkPreference selectCellWithTag: 1];
    
    //[loadImages setState: [wPrefs loadsImagesAutomatically]];
}

- (IBAction)setValueForSender:(id)sender
{
    //WebPreferences *wPrefs = [[WebPreferences alloc] initWithIdentifier: XJ_HISTORY_PREF_IDENT];
    
    if([sender isEqualTo: linkPreference]) {
        int tag = [[sender selectedCell] tag];
        [XJPreferences setOpenHistoryLinksInXjournal: (tag == 0)];
    }
    /*
     else if([sender isEqualTo: loadImages]) {
         [wPrefs setLoadsImagesAutomatically: [sender state]];
     }
     */
}
@end
