//
//  XJHTMLEditView.m
//  Xjournal
//
//  Created by Fraser Speirs on 06/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "XJHTMLEditView.h"


@implementation XJHTMLEditView
- (void)wrapSelectionWithStartTag:(NSString *)startTag endTag:(NSString *)endTag {
	NSRange selection = [self selectedRange];
	if(selection.length > 0) {
		NSString *selectedText = [[self string] substringWithRange: selection];
		[self insertText: [NSString stringWithFormat: @"%@%@%@", startTag, selectedText, endTag]];
		[self setSelectedRange: NSMakeRange(selection.location+[startTag length], selection.length)];
	}
}
@end
