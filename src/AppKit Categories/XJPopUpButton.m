//
//  XJPopUpButton.m
//  Xjournal
//
//  Created by Fraser Speirs on 30/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJPopUpButton.h"


@implementation XJPopUpButton
- (void)awakeFromNib {
	[[self cell] setArrowPosition: NSPopUpNoArrow];
}

/*
 - (void)mouseDown:(NSEvent *)theEvent {
	[self popUpMenuWithEvent: theEvent];
}

- (void)popUpMenuWithEvent: (NSEvent *)theEvent {
	[NSMenu popUpContextMenu: [self menu] 
				   withEvent: theEvent
					 forView: [self superview]];
}
*/
@end
