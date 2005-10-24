//
//  XJMusicPrefClient.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Feb 13 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OmniAppKit/OmniAppKit.h>

@interface XJMusicPrefClient : OAPreferenceClient {
    IBOutlet NSTextField *artistPrefix, *artistSuffix, *albumPrefix, *albumSuffix, *trackPrefix, *trackSuffix, *fieldSeparator, *iTMSPrefix, *iTMSSuffix, *example;
    IBOutlet NSButton *includeMissing;
    IBOutlet NSPopUpButton *ordering;
    IBOutlet NSMatrix *iTMSMatrix;
}

@end
