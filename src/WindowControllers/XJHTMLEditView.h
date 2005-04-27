//
//  XJHTMLEditView.h
//  Xjournal
//
//  Created by Fraser Speirs on 06/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XJHTMLEditView : NSTextView {

}

- (void)wrapSelectionWithStartTag:(NSString *)startTag endTag:(NSString *)endTag;

@end
