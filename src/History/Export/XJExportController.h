//
//  XJExportController.h
//  Xjournal
//
//  Created by Fraser Speirs on 09/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XJExportManager, LJAccount;

@interface XJExportController : NSWindowController {
	IBOutlet NSTabView *tabs;
	
	XJExportManager *exportMgr;
	NSMutableDictionary *plugins;
}

- (void)exportFromAccount: (LJAccount *)acct;
- (IBAction)cancelExport:(id)sender;
- (IBAction)startExport:(id)sender;
@end
