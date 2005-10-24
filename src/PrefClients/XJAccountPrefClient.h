//
//  XJAccountPrefClient.h
//  Xjournal
//
//  Created by Fraser Speirs on Wed Feb 12 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppKit/OmniAppKit.h>

@interface XJAccountPrefClient : OAPreferenceClient {
    //IBOutlet NSTextField *username, *password;

    IBOutlet NSButton *autoLogin, *spellCheckOn, *autoDetectMusic, *openDrawer, *postConfirm;
    IBOutlet NSMatrix *postDateMatrix;
    IBOutlet OAFontView *fontView;
    IBOutlet NSPopUpButton *defaultSecurity, *unsavedOption;
}
- (IBAction) openAccountWindow: (id)sender;
@end
