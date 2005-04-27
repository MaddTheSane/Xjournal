//
//  XJSoftwareUpdate.h
//  Xjournal
//
//  Created by Fraser Speirs on Tue Mar 18 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppKit/OmniAppKit.h>

@interface XJSoftwareUpdate : OAPreferenceClient {
    IBOutlet NSMatrix *enableMatrix;
    IBOutlet NSPopUpButton *frequencyPopup;
}

- (IBAction)setValueForSender: (id) sender;
- (void)updateUI;
@end
