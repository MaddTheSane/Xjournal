//
//  XJDocument.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJDocument.h"
#import "XJPreferences.h"
#import "NetworkConfig.h"
#import "XJSafariBookmarkParser.h";
#import "LJEntryExtensions.h"
#import "XJAccountManager.h"
#import "NSString+Extensions.h"
#import "XJArrayNotEmptyValueTransformer.h"
#import "XJKeywordToImageValueTransformer.h"
#import "XJHTMLPreviewTitleTransformer.h"
#import "XJMusic.h"
#import "NSString+Script.h"
#import "NSString+Templating.h"
#import "XJHTMLEditView.h"
#import "XJGrowlManager.h"

#define kDrawerToggleTag 1000

@interface XJDocument (PrivateAPI)
- (BOOL)iTunesIsRunning;
- (BOOL)iTunesIsPlaying;

// KVO-based Undo
- (void)beginObservingEntry: (LJEntry *)theEntry;
- (void)stopObservingEntry: (LJEntry *)theEntry;
- (void)changeKeyPath: (NSString *)keyPath ofObject: (id)obj toValue: (id)newValue;
@end

@implementation XJDocument
+ (void)initialize {
	[NSValueTransformer setValueTransformer: [[[XJHTMLPreviewTitleTransformer alloc] init] autorelease]
									forName: @"XJHTMLPreviewTitleTransformer"];	
}
- (id)init
{
	self = [super init];
	if(self) {
		[self setAccountManager: [XJAccountManager defaultManager]];
		
		LJEntry *initialEntry = [[LJEntry alloc] init];
		[initialEntry setAccount: [[self accountManager] defaultAccount]];
		[self setEntry: [initialEntry autorelease]];
		
		[NSValueTransformer setValueTransformer: [[[XJArrayNotEmptyValueTransformer alloc] init] autorelease]
										forName: @"XJArrayNotEmptyValueTransformer"];
		
		userpicTransformer = [[XJKeywordToImageValueTransformer alloc] init];
		[userpicTransformer setAccount: [[self entry] account]];
		[NSValueTransformer setValueTransformer: userpicTransformer
										forName: @"XJKeywordToImageValueTransformer"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accountDidLogIn:)
													 name: LJAccountDidLoginNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(insertGlossaryText:)
													 name: XJGlossaryInsertEvent
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accountDeleted:)
													 name: XJAccountRemovedNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(friendsDownloaded:)
													 name: LJAccountDidDownloadFriendsNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(runScriptOnSelection:)
													 name: @"XJRunScriptNotification"
												   object: nil];
		
		[[NSDistributedNotificationCenter defaultCenter] addObserver: self
															selector: @selector(iTunesChangedTrack:)
																name: @"com.apple.iTunes.playerInfo"
															  object: nil
												  suspensionBehavior: NSNotificationSuspensionBehaviorDrop];
	}
    return self;
}

- (id)initWithEntry: (LJEntry *)newentry
{
    [self init];
    [entry release];
    entry = [newentry retain];
    return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	[self stopObservingEntry: [self entry]];
    [entry release];
	[toolbarItemCache release];
	[currentMusic release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    return @"XJDocument"; 
}

- (void)accountDidLogIn: (NSNotification *)note
{
	// This should probably happen automatically in the model.
	if([entry pictureKeyword] == nil && [[note object] isEqualTo: [entry account]]) {
		// Hack this here by stopping observation while we change this
		// because we don't want this change to go into the NSUndoManager
		[self stopObservingEntry: [self entry]];
		[entry setPictureKeyword: [[entry account] defaultUserPictureKeyword]];
		[self beginObservingEntry: [self entry]];
	}
}

- (void)friendsDownloaded: (NSNotification *)note {
	[friendsTable reloadData];
}

// If an account was deleted
- (void)accountDeleted: (NSNotification *)note {
	[entry setJournal: nil];
	[self initUI];
}

- (void)runScriptOnSelection: (NSNotification *) note {
	if([[self window] isMainWindow]) { 
		// Only want the front window to take action
		NSRange selection = [theTextView selectedRange];
		if(selection.length == 0) {
			[entry setContent: [[entry content] stringByRunningShellScript: [note object]]];
		}
		else {
			NSString *selectedText = [[entry content] substringWithRange: selection];
			NSArray *stringParts = [[entry content] componentsSeparatedByString: selectedText];
			NSString *transformedText = [selectedText stringByRunningShellScript: [note object]];
			
			NSString *newContent = [NSString stringWithFormat: @"%@%@%@",
				[stringParts objectAtIndex: 0],
				transformedText,
				[stringParts objectAtIndex: 1]];
			[entry setContent: newContent];				 
			
		}
	}
}

// Window building stuff
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [self initUI];
    [super windowControllerDidLoadNib:aController];
}

- (void)initUI {
    NSToolbar *toolbar;

    // Set up NSToolbar
     toolbar = [[NSToolbar alloc] initWithIdentifier: kEditWindowToolbarIdentifier];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
    [toolbar release];
    
    // Set preferred font
    NSFont *pFont = [XJPreferences preferredWindowFont];
    if(pFont != nil) {
        [theTextView setFont: pFont];
    }
    
    // Set Spell checking on, if required
    [theTextView setContinuousSpellCheckingEnabled: [PREFS boolForKey: XJShouldSpellCheckInNewWindowPreference]];

    // Open the drawer if needed
	if([PREFS boolForKey: XJShouldOpenDrawerInNewWindowPreference])
        [drawer open];

	// Set the preferred entry format
	int tag = [[NSUserDefaults standardUserDefaults] integerForKey: @"DefaultPostFormat"];
	[formatPopup selectItemAtIndex: [formatPopup indexOfItemWithTag: tag]];
	
    NSSize storedSize = NSSizeFromString([PREFS objectForKey: XJEntryWindowSizePreference]);

    NSPoint origin = [[self window] frame].origin;
    NSRect newRect = NSMakeRect(origin.x, origin.y, storedSize.width, storedSize.height);
    [[self window] setFrame: newRect display: YES];
    
    [spinner setStyle: NSProgressIndicatorSpinningStyle];
    [spinner setUsesThreadedAnimation:YES];
}

// ----------------------------------------------------------------------------------------
// Saving stuff
// ----------------------------------------------------------------------------------------
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
    return [entry writePropertyListToFile: fileName atomically: YES];
}

// ===========================================================
// - entry:
// ===========================================================
- (LJEntry *)entry {
    return entry; 
}

// ===========================================================
// - setEntry:
// ===========================================================
- (void)setEntry:(LJEntry *)anEntry {
    if (entry != anEntry) {
        [anEntry retain];
		
		// remove me as an observer to the outgoing entry
		[self stopObservingEntry: entry];
        [entry release];
        entry = anEntry;
		if([entry itemID] == 0) {
// Item hasn't been posted, apply some defaults
			[entry setSubject: @""];
			[entry setCurrentMusic: @""];
			
			switch([[NSUserDefaults standardUserDefaults] integerForKey: @"DefaultPostFormat"]) {
				case 0:	// HTML
					[entry setMarkdownFormat: NO];
					[entry setOptionPreformatted: NO];
					break;
				case 1: // Markdown
					[entry setMarkdownFormat: YES];
					[entry setOptionPreformatted: YES];
					break;
				case 2: // Preformatted
					[entry setMarkdownFormat: NO];
					[entry setOptionPreformatted: YES];
					break;
			}

			[entry setSecurityMode: [XJPreferences defaultSecuritySetting]];
		}
		[self beginObservingEntry: entry];
		
		[friendsTable reloadData];
    }
}

// =========================================================== 
// - accountManager:
// =========================================================== 
- (XJAccountManager *)accountManager {
    return accountManager; 
}

// =========================================================== 
// - setAccountManager:
// =========================================================== 
- (void)setAccountManager:(XJAccountManager *)anAccountManager {
	// Weak reference, no retain
	accountManager = anAccountManager;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    entry = [[LJEntry alloc] init];
    if(entry)
        [entry configureWithContentsOfFile: fileName];
    return entry != nil;
}

- (IBAction)saveWindowSize:(id)sender
{
	NSSize size = [[self window] frame].size;
	[PREFS setObject: NSStringFromSize(size) forKey: XJEntryWindowSizePreference];
}

// ----------------------------------------------------------------------------------------
// Text view delegate things
// ----------------------------------------------------------------------------------------
- (void)textDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == theTextView &&
	   [self htmlPreviewWindow] &&
	   [[self htmlPreviewWindow] isVisible]) 
	{
		if(previewUpdateTimer) {
			[previewUpdateTimer invalidate];
			[previewUpdateTimer release];
			previewUpdateTimer = nil;
		}
		previewUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval: 1
															   target: self
															 selector: @selector(previewUpdateTimerFired:)
															 userInfo: nil
															  repeats: NO] retain];
    }
}

- (void)previewUpdateTimerFired: (NSTimer *)aTimer {
	[previewUpdateTimer invalidate];
	[previewUpdateTimer release];
	previewUpdateTimer = nil;
	
	[self updatePreviewWindow: [entry content]];
}

// This enables shift-tab out of the textfield into the subject field :-)
// See: http://www.omnigroup.com/mailman/archive/macosx-dev/2001-March/010498.html
//
- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;
{
    if (commandSelector == @selector(insertBacktab:)) {
        [theMusicField becomeFirstResponder];
    }
    return NO;
}

// ----------------------------------------------------------------------------------------
// Subject field delegate
// ----------------------------------------------------------------------------------------
- (void)controlTextDidChange: (NSNotification *)aNotification
{
    if([aNotification object] == theSubjectField) {
        if([[[self window] representedFilename] length] == 0) {
            NSString *subjectData = [[aNotification object] stringValue];
            
            // Store the "Untitled xx" string
            if(originalWindowName == nil)
                originalWindowName = [[self window] title];

            // If we have a non-empty string for the subject
            if(subjectData && [subjectData length] > 0) {
                [[self window] setTitle: subjectData];
                [self setHTMLPreviewWindowTitle: subjectData];
            }
            else {
                // If we let the window title go to @"", we lose it from all the windowcontroller's lists
                [[self window] setTitle: originalWindowName];
                [self setHTMLPreviewWindowTitle: originalWindowName];   
            }
        }
        [entry setSubject: [[aNotification object] stringValue]];
    }
}

// ----------------------------------------------------------------------------------------
// Detect Music
// ----------------------------------------------------------------------------------------
- (IBAction)detectMusicNow:(id)sender
{
	[self setCurrentMusic: [XJMusic currentMusicAsiTunesLink:[[NSUserDefaults standardUserDefaults] boolForKey:@"LinkMusicToiTMS"]]];
}

- (void)iTunesChangedTrack: (NSNotification *)note {
	if([[NSUserDefaults standardUserDefaults] boolForKey: @"DetectiTunesChanges"])
		[self detectMusicNow: self];
}

//=========================================================== 
//  currentMusic 
//=========================================================== 
- (XJMusic *)currentMusic {
    return currentMusic; 
}
- (void)setCurrentMusic:(XJMusic *)aCurrentMusic {
    [aCurrentMusic retain];
    [currentMusic release];
    currentMusic = aCurrentMusic;

	NSString *formatString = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey: @"MusicFormatString"];
	
	if(currentMusic != nil) {
		[[self entry] setCurrentMusic: [formatString stringByParsingTagsWithStartDelimeter: @"<$"
																			  endDelimeter: @"/>"
																			   usingObject: [self currentMusic]]];
	}
	else {
		[[self entry] setCurrentMusic: [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey: @"NoMusicString"]];
	}
}


// ----------------------------------------------------------------------------------------
// Posting code
// ----------------------------------------------------------------------------------------
- (void)postEntry:(id)sender
{
    BOOL isPosted = ([entry itemID] != 0);

    if(isPosted) {
        [self postEntryAndDiscardLocalCopy: self];
    }else{

        if([self postEntryAndReturnStatus] && [PREFS boolForKey: XJShouldShowPostingConfirmationDialogPreference]) {
            NSBeginInformationalAlertSheet(NSLocalizedString(@"Posting Succeeded", @""),
                                           NSLocalizedString(@"OK", @""),
                                           NSLocalizedString(@"Open Recent Entries", @""),
                                           nil, /* Other Btn */
                                           [self window],
                                           self, /* id modalDelegate */
                                           @selector(sheetDidEnd:returnCode:contextInfo:), /* SEL didEndSelector */
                                           nil, /* SEL didDismissSelector */
                                           nil, /* void *contextInfo */
                                           NSLocalizedString(@"Your entry was sucessfully posted", @""));
        }
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertAlternateReturn)
        [[NSWorkspace sharedWorkspace] openURL: [[entry journal] recentEntriesHttpURL]];    
}

- (BOOL)postEntryAndReturnStatus
{
    BOOL isPosted = ([entry itemID] != 0);
    
    // Force the first responder to end editing
    [[self window] endEditingFor:nil];
    
    /* 
		Now that we have the XJMusic class, we keep that object around
	 and push the iTMS links in there whenever it changes
    */

	if(![entry itemID] && [[entry currentMusic] length] > 100) {
		[entry setContent: [NSString stringWithFormat: @"%@\n\n%@", [entry content], [entry currentMusic]]];
		[entry setCurrentMusic: @""];
	}
    
    // Check here that network is still reachable
    if([NetworkConfig destinationIsReachable: @"www.livejournal.com"]) {
        NSArray *breaks;
        [spinner startAnimation: self];
        if(![entry optionBackdated]) {
            // Set the posting date according to the user's preference
			BOOL dateEntryByPostingTime = [PREFS boolForKey: XJEntryDateIsWindowCreationTimePreference];
            if(dateEntryByPostingTime && !isPosted) {
                [entry setDate: [NSDate date]];
            }
        }

        // Sanitize linebreaks
        NSString *temp;
        breaks = [[entry content] componentsSeparatedByString: @"\r"];
        temp = [breaks componentsJoinedByString: @"\n"];
        [entry setContent: temp];
		
		// Convert to Markdown
		if([entry markdownFormat]) {
			NSString *markdown = [[entry content] stringByRunningShellScript: [[NSBundle mainBundle] pathForResource: @"Markdown" ofType: @"pl"]];
			[entry setContent: markdown];
		}
		
        NS_DURING
            [entry saveToJournal];
        NS_HANDLER
            NSBeginCriticalAlertSheet([localException name], @"OK", nil, nil,
                                      [self window], nil, nil, nil, nil,
                                      [localException reason]);
            [spinner stopAnimation: self];    
            return NO;
        NS_ENDHANDLER

        [spinner stopAnimation: self];

        return YES;
    } else {
        return NO;
    }
}

- (void)postEntryAndDiscardLocalCopy:(id)sender
{
	if([self fileName] != nil && [self isDocumentEdited]) {  // Was opened from file and is dirty
		int unsavedOption = [PREFS integerForKey: XJShouldAskForUnsavedEntriesPreference];

		if(unsavedOption != kXJShouldDiscardUnsavedEntries) {
			BOOL shouldSave = YES;
			
			if(unsavedOption == kXJShouldAskForUnsavedEntries) {
				NSString *file = [[self fileName] lastPathComponent];
				NSString *msg = [NSString stringWithFormat: @"Do you want to save the changes you made in the document \"%@\"?", file];

				int result = NSRunInformationalAlertPanel(msg,
													  NSLocalizedString(@"Your changes will be posted, but not saved to disk if you don't save them.", @""),
													  NSLocalizedString(@"Save", @""),
													  NSLocalizedString(@"Post Without Saving", @""),
													  nil);
				shouldSave = (result == NSAlertDefaultReturn);
			}
			
			if(shouldSave) {
				[self saveDocument: self];
			}	
		}
	}

    if([self postEntryAndReturnStatus]) {
    	[self close];
        [self closeHTMLPreviewWindow];
        
        if([PREFS boolForKey: XJShouldShowPostingConfirmationDialogPreference]) {
			
			if([PREFS boolForKey: XJShouldShowPostingConfirmationGrowlPreference]) {
				[[XJGrowlManager defaultManager] notifyWithTitle: NSLocalizedString(@"Posting Succeeded", @"")
													 description: NSLocalizedString(@"Your entry was sucessfully posted", @"")
												notificationName: XJEntryDidPostGrowlNotification
														  sticky: NO];
			}
			else {
				int result = NSRunInformationalAlertPanel(NSLocalizedString(@"Posting Succeeded", @""),
														  NSLocalizedString(@"Your entry was sucessfully posted", @""),
														  NSLocalizedString(@"OK", @""),
														  NSLocalizedString(@"Open Recent Entries", @""),
														  nil);
				if(result == NSAlertAlternateReturn)
					[[NSWorkspace sharedWorkspace] openURL: [[entry journal] recentEntriesHttpURL]];
			}
        }
    }
}

// ----------------------------------------------------------------------------------------
// Window Delegate Stuff
// ----------------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
    [htmlPreviewWindow orderOut:self];
    [htmlPreviewWindow release];
    return YES;
}

// ----------------------------------------------------------------------------------------
// HTML Tools
// ----------------------------------------------------------------------------------------
- (IBAction)insertLink:(id)sender
{
    if(!hrefSheet)
        [NSBundle loadNibNamed: @"HREFSheet" owner: self];
    
	NSRange selection = [theTextView selectedRange];
	
    if(selection.length == 0) {
        [html_LinkTextField setStringValue: @""];
		[hrefSheet setInitialFirstResponder: html_LinkTextField];
    } else {
        NSString *selectedText = [[theTextView string] substringWithRange: selection];
        [html_LinkTextField setStringValue: selectedText];
		[hrefSheet setInitialFirstResponder: html_hrefField];
    }

    [self startSheet: hrefSheet];
}

- (IBAction)insertImage:(id)sender
{
    if(!imgSheet)
        [NSBundle loadNibNamed: @"IMGSheet" owner: self];
    [self startSheet: imgSheet];
}

- (IBAction)getImageDimensions:(id)sender {
	NSURL *url = [NSURL URLWithString:[srcField stringValue]];
	
	if(!url) return;
	if(![NetworkConfig destinationIsReachable:[url host]]) return;
	
	NSImage *img = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString:[srcField stringValue]]];
	if(!img) return;
		  
	[sizeWidth setStringValue: [NSString stringWithFormat: @"%d", (int)[img size].width]];
	[sizeHeight setStringValue: [NSString stringWithFormat: @"%d", (int)[img size].height]];
}

- (IBAction)insertBlockquote:(id)sender
{
    [theTextView wrapSelectionWithStartTag: @"<blockquote>"
									endTag: @"</blockquote>"];
}

- (IBAction)insertBold:(id)sender {
	[theTextView wrapSelectionWithStartTag: @"<strong>"
									endTag: @"</strong>"];
}

- (IBAction)insertItalic:(id)sender {
	[theTextView wrapSelectionWithStartTag: @"<em>"
									endTag: @"</em>"];
}

- (IBAction)insertCenter:(id)sender {
	[theTextView wrapSelectionWithStartTag: @"<center>"
									endTag: @"</center>"];
}

- (IBAction)insertUnderline:(id)sender {
	[theTextView wrapSelectionWithStartTag: @"<u>"
									endTag: @"</u>"];
}

- (IBAction)insertCode:(id)sender {
	[theTextView wrapSelectionWithStartTag: @"<code>"
									endTag: @"</code>"];	
}

- (IBAction)insertTT:(id)sender {
	[theTextView wrapSelectionWithStartTag: @"<tt>"
									endTag: @"</tt>"];	
}

- (IBAction)insertLJCut:(id)sender
{
    /*
     Algorithm:
     If there is a selection, assume the user wants to hide it behind a cut
       => Grab the selection and put it in the 'hidden text' field.

     If there's no selection, open an empty sheet.
     */
    NSRange selection = [theTextView selectedRange];
    if(!cutSheet)
        [NSBundle loadNibNamed: @"CutSheet" owner: self];

    if(selection.length == 0) {
        [cut_textField setStringValue: @""];
        [cut_textView setString: @""];
    } else {
        NSString *selectedText = [[theTextView string] substringWithRange: selection];
        [cut_textView setString: selectedText];
    }
    
    [self startSheet: cutSheet];
}

- (IBAction)insertLJUser:(id)sender
{
    NSRange selection = [theTextView selectedRange];
    if(!userSheet)
        [NSBundle loadNibNamed: @"UserSheet" owner: self];
    
    if(selection.length == 0) {
        [self startSheet: userSheet];
    } else {
        [self genericTagWrapWithStart: @"<lj user=\"" andEnd: @"\">"];
    }
}

- (IBAction)setEntryFormat:(id)sender {
	[self setEntryFormatToValue: [[sender selectedItem] tag]];
}

- (void)setEntryFormatToValue: (int)formatType {

	// Prepare UndoManager with current value
	int currentTag = 0;
	
	if([[self entry] markdownFormat])
		currentTag = 1; // If markdown, then 1
	else {
		if([[self entry] optionPreformatted])
			currentTag = 2; // if preformatted then 2
		else
			currentTag = 0; // If neither then 0
	}
	NSLog(@"Preparing undo with tag: %d", currentTag);
	[[[self undoManager] prepareWithInvocationTarget: self] setEntryFormatToValue: currentTag];
	
	// Do the switch
	switch(formatType) {
		case 0: // HTML
			[[self entry] setMarkdownFormat: NO];
			[[self entry] setOptionPreformatted: NO];
			break;
		case 1: // Markdown
			[[self entry] setMarkdownFormat: YES];
			[[self entry] setOptionPreformatted: YES];
			break;
		case 2: // Preformatted
			[[self entry] setMarkdownFormat: NO];
			[[self entry] setOptionPreformatted: YES];
			break;
	}
	NSLog(@"Selecting popup item with Tag: %d", formatType);
	[formatPopup selectItemAtIndex: [formatPopup indexOfItemWithTag: formatType]];
	[self updatePreviewWindow: [entry content]];
}

- (IBAction)commitSheet:(id)sender
{
    if(currentSheet == hrefSheet) {
        // insertHref
        NSString *tagStart = [NSString stringWithFormat: @"<a href=\"%@\"", [html_hrefField stringValue]];
        if([[html_TitleField stringValue] length] > 0)
            tagStart = [tagStart stringByAppendingString: [NSString stringWithFormat: @" title=\"%@\"", [html_TitleField stringValue]]];

        if([[html_targetCombo stringValue] length] > 0)
            tagStart = [tagStart stringByAppendingString: [NSString stringWithFormat: @" target=\"%@\"", [html_targetCombo stringValue]]];

        tagStart = [tagStart stringByAppendingString: @">"];

		tagStart = [tagStart stringByAppendingString: [html_LinkTextField stringValue]];
		tagStart = [tagStart stringByAppendingString: @"</a>"];
		[self insertStringAtSelection: tagStart];
		
        //[self genericTagWrapWithStart: tagStart andEnd: @"</a>"];
    }
    else if(currentSheet == imgSheet) {
        NSString *tag = [NSString stringWithFormat: @"<img src=\"%@\"", [srcField stringValue]];

        if([altField stringValue] != nil && [[altField stringValue] length] > 0) {
            tag = [tag stringByAppendingString: [NSString stringWithFormat: @" alt=\"%@\"", [altField stringValue]]];
        }
        
        if([[sizeWidth stringValue] length] > 0 && [[sizeHeight stringValue] length] > 0) {
            NSString *h=[sizeHeight stringValue], *w=[sizeWidth stringValue];
            if(h != nil && [h length] > 0)
                tag = [tag stringByAppendingString: [NSString stringWithFormat: @" width=\"%@\"", w]];

            if(w != nil && [w length] > 0)
                tag = [tag stringByAppendingString: [NSString stringWithFormat: @" height=\"%@\"", h]];
        }

        if([[spaceWidth stringValue] length] > 0 && [[spaceHeight stringValue] length] > 0) {
            NSString *h=[spaceHeight stringValue], *w=[spaceWidth stringValue];
            if(h != nil && [h length] > 0)
                tag = [tag stringByAppendingString: [NSString stringWithFormat: @" hspace=\"%@\"", w]];

            if(w != nil && [w length] > 0)
                tag = [tag stringByAppendingString: [NSString stringWithFormat: @" vspace=\"%@\"", h]];
        }

        if([[alignPop selectedItem] tag] != 0) {
            NSString *alignment = [alignPop titleOfSelectedItem];
            tag = [tag stringByAppendingString: [NSString stringWithFormat: @" align=\"%@\"", alignment]];
        }

        if([[borderSize stringValue] length] > 0){
            NSString *b = [borderSize stringValue];
            tag = [tag stringByAppendingString: [NSString stringWithFormat: @" border=\"%@\"", b]];
        }

        tag = [tag stringByAppendingString: @">"];
        
        [self insertStringAtSelection:tag];
    }
    else if(currentSheet == userSheet) {
        NSString *username = [user_nameCombo stringValue];
        [self insertStringAtSelection: [NSString stringWithFormat: @"<lj user=\"%@\">", username]];
    }
    else if(currentSheet == cutSheet) {
        NSString *cutText = [cut_textField stringValue];
        NSString *hiddenText = [cut_textView string];
        NSString *cutString = @"<lj-cut";

        if(cutText != nil && [cutText length] >0) {
            cutString = [cutString stringByAppendingString: [NSString stringWithFormat: @" text=\"%@\"", cutText]];
        }
        cutString = [cutString stringByAppendingString: @">"];

        if(hiddenText != nil && [hiddenText length] >0) {
            cutString = [cutString stringByAppendingString: [NSString stringWithFormat: @"%@</lj-cut>", hiddenText]];
        }
        [self insertStringAtSelection: cutString];
    }
    [self closeSheet: self];
}

- (IBAction)closeSheet:(id)sender
{
    [NSApp endSheet: currentSheet];
    [currentSheet orderOut: nil];
    currentSheet = nil;
}

- (void)startSheet:(NSWindow *)sheet
{
    currentSheet = sheet;
    [NSApp beginSheet: currentSheet
       modalForWindow: [self window]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
}

- (void)genericTagWrapWithStart: (NSString *)tagStart andEnd: (NSString *)tagEnd
{
    id responder = [[self window] firstResponder];
    // check here that responder is a text class, then use the RESPONDER'S selectedRange
    if([responder respondsToSelector: @selector(selectedRange)]) {
        NSRange selection = [responder selectedRange];
        [responder insertText: [NSString stringWithFormat: @"%@%@%@", tagStart, [[responder string] substringWithRange: selection], tagEnd]];
        [responder setSelectedRange: NSMakeRange(selection.location+[tagStart length], selection.length)];
    }
}

- (void)insertStringAtSelection:(NSString *)newString
{
    [[[self window] firstResponder] insertText: newString];
}

- (void) insertGlossaryText: (NSNotification *)note
{
    [self insertStringAtSelection: [note object]];
}

// Button enablers for User and comm sheets
- (IBAction)enableOKButton:(id)sender
{
    if(currentSheet == userSheet)
        [user_OKButton setEnabled: [[sender stringValue] length] > 0];
    else if(currentSheet == commSheet)
        [comm_OKButton setEnabled: [[sender stringValue] length] > 0];
}

- (BOOL)validateToolbarItem:(id)item
{
    if([[item itemIdentifier] isEqualToString: kEditPostItemIdentifier] || [[item itemIdentifier] isEqualToString: kEditPostAndDiscardItemIdentifier])
        if(![[[entry journal] account] isLoggedIn])
            return NO;
    return YES;
}

- (BOOL)validateMenuItem:(id)item
{
	if([item tag] == kDrawerToggleTag) {
		if([drawer state] == NSDrawerOpenState || [drawer state] == NSDrawerOpeningState)
			[item setTitle: NSLocalizedString(@"Hide Info", @"")];
		else
			[item setTitle: NSLocalizedString(@"Show Info", @"")];
	}
	return YES;
}

- (NSWindow *)window
{
    return [[[self windowControllers] objectAtIndex: 0] window];
}

// ----------------------------------------------------------------------------------------
// Community and user combo box data source
// ----------------------------------------------------------------------------------------
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    LJAccount *acct = [[entry journal] account];

    if(aComboBox == user_nameCombo) {
        return [[acct friendArray] count];
    }
    else if(aComboBox == comm_nameCombo) {
        return [[acct joinedCommunityArray] count];
    }

    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    LJAccount *acct = [[entry journal] account];
    
    if(aComboBox == user_nameCombo)
        return [[[acct friendArray] objectAtIndex: index] username];
    else if(aComboBox == comm_nameCombo) {
        return [[[acct joinedCommunityArray] objectAtIndex: index] username];
    }
    return @"";
}

- (IBAction)toggleDrawer: (id)sender
{
    [drawer toggle: sender];
	
	if([drawer state] == NSDrawerOpenState || [drawer state] == NSDrawerOpeningState)
		[sender setTitle: NSLocalizedString(@"Hide Info", @"")];
	else
		[sender setTitle: NSLocalizedString(@"Show Info", @"")];
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource - friend group security
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if([[self entry] account])
        return [[[[self entry] account] groupArray] count];

	NSLog(@"returning zero groups for account");
	return 0;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if([[self entry] account])
    {
        NSArray *groups = [[[self entry] account] groupArray];
        if([groups count] > 0) {
            LJGroup *rowGroup = [groups objectAtIndex: rowIndex];

            if([[aTableColumn identifier] isEqualToString: @"name"])
                return [rowGroup name];
            else {
                if([entry accessAllowedForGroup: rowGroup])
                    return [NSNumber numberWithBool: YES];
                else
                    return [NSNumber numberWithBool: NO];
            }
        }
    }
    return @"";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSArray *groups = [[[self entry] account] groupArray];
    LJGroup *rowGroup = [groups objectAtIndex: rowIndex];

    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [[self entry] setAccessAllowed: [anObject boolValue] forGroup: rowGroup];
    }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [aCell setEnabled: [entry securityMode] == LJGroupSecurityMode];
    }
}

// ----------------------------------------------------------------------------------------
// HTML Preview
// ----------------------------------------------------------------------------------------
- (IBAction)showPreviewWindow: (id)sender
{
    if(!htmlPreviewWindow) {
        [NSBundle loadNibNamed:@"HTMLPreview" owner: self];
    }
    [self setHTMLPreviewWindowTitle: [[self window] title]];

    [htmlPreviewWindow makeKeyAndOrderFront: sender];
    [self updatePreviewWindow: [entry content]];
}

- (NSWindow *)htmlPreviewWindow { return htmlPreviewWindow; }
- (WebView *)htmlPreview { return htmlPreview; }

- (void)updatePreviewWindow: (NSString *)textContent
{
	if([[self entry] markdownFormat]) {
		[markdownSpinner startAnimation: self];
		[disclosableView show: self];
		NSString *mdPath = [[NSBundle mainBundle] pathForResource: @"Markdown" ofType: @"pl"];
		textContent = [textContent stringByRunningShellScript: mdPath];
		[disclosableView hide:self];
		[markdownSpinner stopAnimation: self];
	}
	
    if([self htmlPreviewWindow] && [[self htmlPreviewWindow] isVisible]) {
        textContent = [textContent translateLJUser];
        textContent = [textContent translateLJComm];
        textContent = [textContent translateLJCutOpenTagWithText];
        textContent = [textContent translateBasicLJCutOpenTag];
        textContent = [textContent translateLJCutCloseTag];
       
        if(![entry optionPreformatted])
            textContent = [textContent translateNewLines];
        
        textContent = [NSString stringWithFormat: @"<html><head><style type=\"text/css\">.xjljcut { background-color: #CCFFFF; padding-top: 5px; padding-bottom: 5px }</style></head><body>%@</body</html>", textContent];
        [[htmlPreview mainFrame] loadHTMLString: textContent  baseURL: nil];
    }
}

- (void)setHTMLPreviewWindowTitle:(NSString *)title
{
    NSString *newTitle = [NSString stringWithFormat: @"%@ [HTML Preview]", title];
    if(htmlPreviewWindow)
        [[self htmlPreviewWindow] setTitle: newTitle];
}

- (void)closeHTMLPreviewWindow {
    [htmlPreviewWindow orderOut:self];
}

// ----------------------------------------------------------------------------------------
// Web View delegates
// ----------------------------------------------------------------------------------------
- (void) webView: (WebView *) sender  decidePolicyForNavigationAction: (NSDictionary *) actionInformation request: (NSURLRequest *) request frame: (WebFrame *) frame decisionListener: (id<WebPolicyDecisionListener>) listener
{
    int key = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    switch(key){
        case WebNavigationTypeLinkClicked:
            // Since a link was clicked, we want WebKit to ignore it
            [listener ignore];
            // Instead of opening it in the WebView, we want to open
            // the URL in the user's default browser
            [[NSWorkspace sharedWorkspace] openURL: [actionInformation objectForKey:WebActionOriginalURLKey]];
            break;
        default:
            [listener use];
            // You could also call [listener download] here.
    }
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (sender == htmlPreview)
    {
        //[[frame frameView] _scrollToBottomLeft];
    }	
}
@end

@implementation XJDocument (PrivateAPI)
- (BOOL) iTunesIsRunning
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
    NSEnumerator *allapps = [apps objectEnumerator];
    NSDictionary *thisApp;

    while(thisApp = [allapps nextObject]) {
        NSString *appName = [thisApp objectForKey: @"NSApplicationName"];
        if([appName isEqualToString: @"iTunes"]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)iTunesIsPlaying
{
    if([self iTunesIsRunning]) {
        NSAppleScript *script;
        NSAppleEventDescriptor *result;
        NSDictionary *dict;

        script = [[[NSAppleScript alloc] initWithSource: @"tell application \"iTunes\" to artist of current track"] autorelease];
        result = [script executeAndReturnError: &dict];
        if(!result) {
            return NO;
        }
        else {
            if([result stringValue] == nil)
                return NO;
            else
                return YES;
        }
    }
    else
        return NO;
}

- (void)beginObservingEntry: (LJEntry *)theEntry {
	NSArray *observedPaths = [NSArray arrayWithObjects: 
		@"subject", @"securityMode", @"currentMusic", @"currentMood", @"account", 
		@"optionPreformatted", @"optionNoEmail", @"optionBackdated", @"date", 
		@"securityMode", @"pictureKeyword", @"markdownFormat", nil];
	
	NSEnumerator *en = [observedPaths objectEnumerator];
	NSString *path;
	while(path = [en nextObject]) {
		
		[theEntry addObserver: self
				   forKeyPath: path
					  options: NSKeyValueObservingOptionOld
					  context: nil];
	}
}

- (void)stopObservingEntry: (LJEntry *)theEntry {
	NSArray *observedPaths = [NSArray arrayWithObjects: 
		@"subject", @"securityMode", @"currentMusic", @"currentMood", @"account", 
		@"optionPreformatted", @"optionNoEmail", @"optionBackdated", @"date", 
		@"securityMode", @"pictureKeyword", @"markdownFormat", nil];
	
	NSEnumerator *en = [observedPaths objectEnumerator];
	NSString *path;
	while(path = [en nextObject]) {
		[theEntry removeObserver: self forKeyPath: path];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context 
{
	NSLog(@"Observe value for KeyPath: %@", keyPath);
	if([keyPath isEqualToString: @"account"]) {
		[friendsTable reloadData];
		[userpicTransformer setAccount: [[self entry] account]];
	}
	else {
		// Set the undo manager
		NSUndoManager *undoManager = [self undoManager];	
		id oldValue = [change valueForKey: NSKeyValueChangeOldKey];

		if([oldValue isEqualTo: [NSNull null]])
			oldValue = @"";
		[[undoManager prepareWithInvocationTarget: self] changeKeyPath: keyPath
															  ofObject: object
															   toValue: oldValue];
	}
	
	[self updatePreviewWindow: [entry content]];
}

- (void)changeKeyPath: (NSString *)keyPath
			 ofObject: (id)obj
			  toValue: (id)newValue 
{
	[obj setValue: newValue forKey: keyPath];
}
@end
