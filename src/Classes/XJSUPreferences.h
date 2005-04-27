//
//  XJSUPreferences.h
//  XJSoftwareUpdate
//
//  Created by Fraser Speirs on Wed Apr 16 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OmniAppKit/OmniAppKit.h>
#import <OmniFoundation/OmniFoundation.h>

@interface XJSUPreferences : OAPreferenceClient {
    IBOutlet NSButton *checkNowButton;
    IBOutlet NSMatrix *enableMatrix;
    IBOutlet NSPopUpButton *frequencyPopup;
    IBOutlet NSTextField *infoTextField;
}

- (IBAction) checkNow: (id)sender;
- (IBAction) setValueForSender: (id)sender;
- (void)updateUI;
@end
