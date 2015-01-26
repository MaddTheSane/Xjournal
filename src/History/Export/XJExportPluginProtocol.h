/*
 *  XJExportPluginProtocol.h
 *  Xjournal
 *
 *  Created by Fraser Speirs on 09/12/2004.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include <Cocoa/Cocoa.h>

@protocol XJExportPluginProtocol

// Intitialise with the given export manager
// Return nil if initialisation failed.
- (id)initWithExportManager:(id)exportManager bundle: (NSBundle *)plugBundle;

// Provide your plugin's NSView
- (NSView *)pluginView;

// Provide your plugin's visible name
- (NSString *)visibleName;

// Provide some RTF(d) that describes your plugin
// Return nil if you're not interested
- (NSAttributedString *)pluginDescription;

// Provide an NSURL for your plugin's home page
- (NSURL *)homePageURL;

// Provide your plugin's identifier
- (NSString *)identifier;

// Does your plugin want a file or directory selection from the user
- (BOOL)wantsDestinationPrompt;

// Your chance to customise the NSSavePanel
// It will always be supplied to this method
// configured for saving a file.
- (void)customiseSavePanel: (NSSavePanel *)savePanel;

// Do the export
- (void)export;
@end

