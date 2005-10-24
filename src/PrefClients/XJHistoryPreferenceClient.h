//
//  XJHistoryPreferenceClient.h
//  Xjournal
//
//  Created by Fraser Speirs on Fri Jun 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppkit/OmniAppkit.h>
#import <WebKit/WebKit.h>

@interface XJHistoryPreferenceClient : OAPreferenceClient {
    IBOutlet NSMatrix *linkPreference;
    //IBOutlet NSButton *loadImages;
}
- (IBAction)setValueForSender:(id)sender;
@end
