//
//  XJPopUpButton.h
//  testXJUI
//
//  Created by Alistair McMillan on 12/05/2008.
//  Copyright 2008 Alistair McMillan. All rights reserved.
//
//  Based on http://www.jimmcgowan.net/Site/Blog/Entries/2007/8/27_Adding_a_Menu_to_an_NSButton.html

#import <Cocoa/Cocoa.h>

@interface XJPopUpButton : NSButton {
	IBOutlet NSMenu *popUpMenu;
	NSPopUpButtonCell *popUpCell;
}

- (void)awakeFromNib;
- (void)mouseDown:(NSEvent*)event;
- (void)menuClosed:(NSNotification*)note;
- (void)dealloc;

@end
