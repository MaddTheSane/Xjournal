//
//  XJAccountPrefClient.m
//  Xjournal
//
//  Created by Fraser Speirs on Wed Feb 12 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJAccountPrefClient.h"
#import "KeyChain.h"
#import "XJPreferences.h"

@implementation XJAccountPrefClient
- (void)setValueForSender:(id)sender
{
    if([sender isEqualTo: autoLogin]) {
        [defaults setBool: [sender state] forKey: PREFS_AUTO_LOGIN];
    }
    else if([sender isEqualTo: spellCheckOn]) {
        [defaults setBool: [sender state] forKey: SPELLCHECK_BY_DEFAULT];
    }
    else if([sender isEqualTo: autoDetectMusic]) {
        [defaults setBool: [sender state] forKey: PREFS_MUSIC_AUTO_DETECT];
    }
    else if([sender isEqualTo: postDateMatrix]) {
        [defaults setInteger: [[sender selectedCell] tag] forKey: PREFS_DEFAULT_POST_DATE];
    }
    else if([sender isEqualTo: openDrawer]) {
        [defaults setBool: [sender state] forKey: PREFS_OPEN_DRAWER];
    }
    else if([sender isEqualTo: postConfirm]) {
        [defaults setBool: [sender state] forKey: SHOW_POST_CONFIRM_DIALOG];
    }
    else if([sender isEqualTo: defaultSecurity]) {
        [defaults setInteger: [[sender selectedItem] tag] forKey: XJ_DEFAULT_SECURITY];
    }
    else if([sender isEqualTo: unsavedOption]) {
    	[defaults setInteger: [[sender selectedItem] tag] forKey: XJ_UNSAVED_OPTION];
    }
}

- (void)updateUI
{
    [autoLogin setState: [defaults boolForKey: PREFS_AUTO_LOGIN]];
    [spellCheckOn setState: [defaults boolForKey: SPELLCHECK_BY_DEFAULT]];
    [autoDetectMusic setState: [defaults boolForKey: PREFS_MUSIC_AUTO_DETECT]];
    [postDateMatrix selectCellWithTag: [defaults integerForKey: PREFS_DEFAULT_POST_DATE]];
    [openDrawer setState: [defaults boolForKey: PREFS_OPEN_DRAWER]];
    [postConfirm setState: [defaults boolForKey: SHOW_POST_CONFIRM_DIALOG]];
    
    [defaultSecurity selectItemWithTag: [defaults integerForKey: XJ_DEFAULT_SECURITY]];
    [unsavedOption selectItemWithTag: [defaults integerForKey: XJ_UNSAVED_OPTION]];
    
    NSFont *prefsFont = [XJPreferences preferredWindowFont];
    if(prefsFont != nil) {
        [fontView setFont: prefsFont];
    }
}

// Font view delegate
- (BOOL)fontView:(OAFontView *)aFontView shouldChangeToFont:(NSFont *)newFont
{
    return YES;
}

- (void)fontView:(OAFontView *)aFontView didChangeToFont:(NSFont *)newFont
{
    [XJPreferences setPreferredWindowFont: newFont];
}

// We pass along the NSFontPanel delegate message, adding in the last font view to have been sent -setFontUsingFontPanel:
 - (BOOL)fontView:(OAFontView *)aFontView fontManager:(id)sender willIncludeFont:(NSString *)fontName
{
    return YES;
}

- (IBAction) openAccountWindow: (id)sender
{
    [NSApp sendAction: @selector(showAccountEditWindow:) to: nil from: self];
}
@end
