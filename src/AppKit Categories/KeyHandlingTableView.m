//
//  KeyHandlingTableView.m
//  Xjournal
//
//  Created by Fraser Speirs on Thu Apr 17 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "KeyHandlingTableView.h"

/*
 * Define our delegate methods, so as to avoid compiler assumptions about
 * parameters and return values.
 *   --sparks
 */
@interface KeyHandlingTableViewDelegate
- (void) handleDeleteKeyInTableView:(NSTableView *) aTableView;
@end

@implementation KeyHandlingTableView

/*
 * This category overrides -keyDown to provide an additional delegate 
 * method for when the user presses delete on the table.
 */
- (void)keyDown:(NSEvent *)event {
    
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    unsigned int flags = [event modifierFlags];

    if (key == NSDeleteCharacter &&
        flags == 0 &&
        [self numberOfRows] > 0 &&
        [self selectedRow] != -1) {
        
        if([[self delegate] respondsToSelector:@selector(handleDeleteKeyInTableView:)])
            [[self delegate] handleDeleteKeyInTableView: self];
    }
    else {
        [super keyDown:event]; // let somebody else handle the event
    }
}
@end
