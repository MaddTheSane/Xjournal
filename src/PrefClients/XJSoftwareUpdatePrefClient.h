//
//  XJSoftwareUpdatePrefClient.h
//  Xjournal
//
//  Created by Fraser Speirs on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppKit/OmniAppKit.h>

@interface XJSoftwareUpdatePrefClient : OAPreferenceClient {
    IBOutlet NSPopUpButton *frequency;
    IBOutlet NSMatrix *autoButtons;
}
- (IBAction)checkNow: (id)sender;
@end
