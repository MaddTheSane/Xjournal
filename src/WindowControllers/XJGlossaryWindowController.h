//
//  XJGlossaryWindowController.h
//  Xjournal
//
//  Created by Fraser Speirs on Thu Jan 23 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface XJGlossaryWindowController : NSWindowController {
    IBOutlet NSTextView *textView;
	NSMutableArray *glossary;
}

- (NSMutableArray *)glossary;
- (void)setGlossary:(NSMutableArray *)aGlossary;

- (BOOL)fileExists:(NSString *)path;

- (void)readGlossaryFile;
- (void)writeGlossaryFile;
- (void)writeExampleGlossaryFile;
@end
