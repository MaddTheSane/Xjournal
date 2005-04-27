//
//  XJSUController.h
//  XJSoftwareUpdate
//
//  Created by Fraser Speirs on Wed Apr 16 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJSUController : NSObject {
    NSPanel *panel;
    NSImageView *appIconView;
    NSTextField *mainMessageField;
    NSTextField *moreMessageField;
    NSTextView *releaseNotesView;
    NSTextField *warningField;
    NSImageView *warningIconView;
}
+ sharedController;
+ (void)checkSynchronouslyWithUIAttachedToWindow: (id)sender;
+ (void)newVersionAvailable: (id)sender;

- (void)downloadNow: (NSString *)downloadURL;
- (IBAction)showMoreInfo: (NSString *)urlPage;
@end
