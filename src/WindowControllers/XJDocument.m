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
#import "MusicStringFormatter.h"
#import "XJSafariBookmarkParser.h";
#import "LJEntryExtensions.h"
#import "XJAccountManager.h"
#import "NSString+Extensions.h"

#define DOC_TEXT @"document.text"
#define DOC_SUBJECT @"document.subject"

@interface XJDocument (PrivateAPI)
- (BOOL)iTunesIsRunning;
- (BOOL)iTunesIsPlaying;
@end

@implementation XJDocument
#pragma mark -
#pragma mark Initialisation
- (id)init
{
    if([super init] == nil)
        return nil;
    
    [self setEntry: [[[LJEntry alloc] init] autorelease]];
	
    if([[XJAccountManager defaultManager] loggedInAccount]) {
        [[self entry] setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(manualLoginSuccess:)
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
    return self;
}

- (id)initWithEntry: (LJEntry *)newentry
{
    [self init];
    [self setEntry: newentry];
    return self;
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
	
    // Configure the table
    NSButtonCell *tPrototypeCell = [[NSButtonCell alloc] initTextCell: @""];
    [tPrototypeCell setEditable: YES];
    [tPrototypeCell setButtonType:NSSwitchButton];
    [tPrototypeCell setImagePosition:NSImageOnly];
    [tPrototypeCell setControlSize:NSSmallControlSize];
	
    [[friendsTable tableColumnWithIdentifier: @"check"] setDataCell: tPrototypeCell];
    [tPrototypeCell release];
	
    if([[self entry] itemID] == 0) {
        // Item hasn't been posted, apply default security mode
        int level = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJDefaultSecurityLevel"] intValue];
        [security selectItemWithTag: level];
        [[self entry] setSecurityMode:level];
    }else {
        [security selectItemWithTag: [[self entry] securityMode]];
    }
    
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    /*
     We really want to check here of the network is reachable, because if it isn't
     certain things will have to be disabled:
     * Journal selection
     * Security selection
     * Userpic Selection
     * Mood selection
     */
    if([NetworkConfig destinationIsReachable: @"www.livejournal.com"] && [[XJAccountManager defaultManager] loggedInAccount]) {
        if([[self entry] journal] == nil)
            [[self entry] setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];
        [self buildJournalPopup];
        [self buildMoodPopup];
        [userpic setMenu: [[[XJAccountManager defaultManager] loggedInAccount] userPicturesMenu]];
        [userPicView setImage: [XJPreferences imageForURL: [[userpic selectedItem] representedObject]]];
    } else {
        [journalPop setEnabled: NO];
        [moods setEnabled: NO];
        [userpic setEnabled: NO];
        [security setEnabled: NO];
    }
	
    // Sync the UI up to the state of the Entry object
	if([[self entry] tags] != nil) {
		[theTagField setStringValue: [[self entry] tags]];
	}
    
    if([[self entry] currentMusic] != nil) {
        [theMusicField setStringValue: [[self entry] currentMusic]];
    } else {
        if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJMusicShouldAutoDetect"] boolValue] &&
		   [[self entry] itemID] == 0) {
            [self detectMusicNow: self];
        }
    }
	
    if([[self entry] pictureKeyword] != nil) {
        [userpic selectItemWithTitle: [[self entry] pictureKeyword]];
        [userPicView setImage: [XJPreferences imageForURL: [[userpic selectedItem] representedObject]]];
    }
	
    if([[self entry] currentMood] != nil) {
        [moods setStringValue: [[self entry] currentMood]];
    }
    
    [journalPop selectItemAtIndex: [[journalPop menu] indexOfItemWithRepresentedObject: [[self entry] journal]]];
	
    // Set the option checkboxes
    [preformattedChk setState: [[self entry] optionPreformatted]];
    [noCommentsChk setState: [[self entry] optionNoComments]];
    [noEmailChk setState: [[self entry] optionNoEmail]];
    [backdatedChk setState: [[self entry] optionBackdated]];
    [backdateField setEnabled: [[self entry] optionBackdated]];
    
    // Set preferred font
    NSFont *pFont = [XJPreferences preferredWindowFont];
    if(pFont != nil) {
        [theTextView setFont: pFont];
    }
    
    // Set Spell checking on, if required
	BOOL shouldSpellCheck = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJSpellCheckByDefault"] boolValue];
    [theTextView setContinuousSpellCheckingEnabled: shouldSpellCheck];
	
    // Open the drawer if needed
	if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJShouldOpenDrawerInNewWindow"] boolValue])
        [drawer open];
	
	NSString *storedSizeString = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJEntryWindowSize"];
	NSSize storedSize = NSMakeSize(500, 510);
	if(storedSizeString == nil)
		storedSize = NSSizeFromString(storedSizeString);
	
    NSPoint origin = [[self window] frame].origin;
    NSRect newRect = NSMakeRect(origin.x, origin.y, storedSize.width, storedSize.height);
    [[self window] setFrame: newRect display: YES];
    
    [spinner setStyle: NSProgressIndicatorSpinningStyle];
    [spinner setUsesThreadedAnimation:YES];
	
    if([[XJAccountManager defaultManager] loggedInAccount])
        [statusField setStringValue: [NSString stringWithFormat: @"Logged in as %@", [[[XJAccountManager defaultManager] loggedInAccount] username]]];
}

- (void)manualLoginSuccess: (NSNotification *)note
{
    [self buildJournalPopup];
    [self buildMoodPopup];
    [userpic setMenu: [[[XJAccountManager defaultManager] loggedInAccount] userPicturesMenu]];
    [userPicView setImage: [XJPreferences imageForURL: [[userpic selectedItem] representedObject]]];

    [journalPop setEnabled: YES];
    [moods setEnabled: YES];
    [userpic setEnabled: YES];
    [security setEnabled: YES];

    [[self entry] setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];

    // If User and Community sheets are laoded, reload their combo boxes
    if(userSheet)
        [user_nameCombo reloadData];

    if(commSheet)
        [comm_nameCombo reloadData];

    [friendsTable reloadData];
    
    [statusField setStringValue: [NSString stringWithFormat: @"Logged in as %@", [[[XJAccountManager defaultManager] loggedInAccount] username]]];
}

// If an account was deleted
- (void)accountDeleted: (NSNotification *)note {
	[[self entry] setJournal: nil];
	[self initUI];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [entry release];
	[toolbarItemCache release];
	[iTMSLinks release];
    [super dealloc];
}

// ==================================
#pragma mark -
#pragma mark NSDocumenty stuff
// ==================================
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    return @"XJDocument";
}

- (NSWindow *)window { return [[[self windowControllers] objectAtIndex: 0] window]; }

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [self initUI];
    [super windowControllerDidLoadNib:aController];
}




// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Popup Building
// ----------------------------------------------------------------------------------------
- (void) buildJournalPopup
{
    NSMenu *jMenu = [[[XJAccountManager defaultManager] loggedInAccount] journalMenu];
    [journalPop setMenu: jMenu];        
}

- (void)buildMoodPopup
{
    LJAccount *acct = [[XJAccountManager defaultManager] loggedInAccount];
    if(acct) {
        [moods setDataSource: [acct moods]];
        [moods reloadData];
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Saving
// ----------------------------------------------------------------------------------------
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
    return [[self entry] writePropertyListToFile: fileName atomically: YES];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    [self setEntry: [[[LJEntry alloc] init] autorelease]];
	[[self entry] configureWithContentsOfFile: fileName];
    return YES;
}

- (IBAction)saveWindowSize:(id)sender {
	NSString *sizeString = NSStringFromSize([[self window] frame].size);
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: sizeString
																		forKey: @"XJEntryWindowSize"];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Text view delegate things
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

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
#warning Remove most of this in favour of bindings
    if([aNotification object] == theMusicField) {
        // If the user types stuff in the field, we 
        // invalidate the iTMS links since we can only generate them
        // directly from iTunes and not from back-parsing the user's
        // entry
        if(![[[aNotification object] stringValue] isEqualToString: [[self entry] currentMusic]]) { 
            iTMSLinks = nil;
        }
        [[self entry] setCurrentMusic: [[aNotification object] stringValue]];        
    }
	else if([aNotification object] == theTagField) {
		[[self entry] setTags: [[aNotification object] stringValue]];
	}
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Popup Menu targets
// ----------------------------------------------------------------------------------------
- (IBAction)setSelectedJournal:(id)sender {
    [[self entry] setJournal: [[sender selectedItem] representedObject]];
}

- (IBAction)setSelectedMood:(id)sender {
    [[self entry] setCurrentMood: [sender stringValue]];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Music Detection
// ----------------------------------------------------------------------------------------
- (IBAction)detectMusicNow:(id)sender
{
    /*
     What we do here is generate both iTMS links and regular music text.
     Keep both around and show the regular links in the UI.  At posting time,
     if the user wants iTMS links, we remove them from the Current Music 
     field and put it in the end of the post.
     */
  
    iTMSLinks = [[MusicStringFormatter detectMusicAndFormat: YES] retain];
    
    NSString *music = [MusicStringFormatter detectMusicAndFormat:NO];
    
    if(music) { 
        [theMusicField setStringValue: music];
        [[self entry] setCurrentMusic: music];
    } else {
        NSString *alternativeValue = [PREFS stringForKey: @"NoMusicString"];
        if(!alternativeValue)
            alternativeValue = @"";
        [theMusicField setStringValue: alternativeValue];
        [[self entry] setCurrentMusic: alternativeValue];
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Posting
// ----------------------------------------------------------------------------------------
- (void)postEntry:(id)sender
{
    BOOL isPosted = ([[self entry] itemID] != 0);

    if(isPosted) {
        [self postEntryAndDiscardLocalCopy: self];
    }else{

        if([self postEntryAndReturnStatus] && 
		   [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJShouldShowPostingConfirmationDialog"] boolValue])
		{
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
        [[NSWorkspace sharedWorkspace] openURL: [[[self entry] journal] recentEntriesHttpURL]];    
}

- (BOOL)postEntryAndReturnStatus
{
    BOOL isPosted = ([[self entry] itemID] != 0);
    
    // Force the first responder to end editing
    [[self window] endEditingFor:nil];
    
    /* Check if the user wants iTMS links instead of current music.
        Also, only do this if this isn't a repost. 
        
        Consider, also, the case where the user has entered 
        music text by themselves instead of getting it via the button.
        In such a case, iTMSLinks will be nil.
    
        Also, if we detected iTMS links, but the user has since cleared 
        the music field, we don't want to do anything.
    */
    if(![[self entry] itemID] &&
	   [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJLinkMusicToStore"] boolValue] &&
	   iTMSLinks) {
        [[self entry] setCurrentMusic: nil];
        [[self entry] setContent: [NSString stringWithFormat: @"%@\n\n%@", [[self entry] content], iTMSLinks]];
    }
    
    
    // Check here that network is still reachable
    if([NetworkConfig destinationIsReachable: @"www.livejournal.com"]) {
        NSArray *breaks;
        [spinner startAnimation: self];
        if(![[self entry] optionBackdated]) {
            // Set the posting date according to the user's preference
			BOOL entryIsDatedAtPost = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJPostingDate"] boolValue];
            if(entryIsDatedAtPost && !isPosted) {
                [[self entry] setDate: [NSDate date]];
            }
        }

        // Sanitize linebreaks
        NSString *temp;
        breaks = [[[self entry] content] componentsSeparatedByString: @"\r"];
        temp = [breaks componentsJoinedByString: @"\n"];
        [[self entry] setContent: temp];
        NS_DURING
            [[self entry] saveToJournal];
        NS_HANDLER
            NSBeginCriticalAlertSheet([localException name], @"OK", nil, nil,
                                      [self window], nil, nil, nil, nil,
                                      [localException reason]);
            [spinner stopAnimation: self];    
            return NO;
        NS_ENDHANDLER

        [spinner stopAnimation: self];

        if(!isPosted) // Only fire this if it's not an edit
            [[NSNotificationCenter defaultCenter] postNotificationName:XJEntryEntryPostedNotification object:entry];
        else
            [[NSNotificationCenter defaultCenter] postNotificationName:XJEntryEditedNotification object:entry];
        return YES;
    } else {
        return NO;
    }
}

- (void)postEntryAndDiscardLocalCopy:(id)sender
{
	if([self fileName] != nil && [self isDocumentEdited]) {  // Was opened from file and is dirty
		int unsavedOption = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJUnsavedOption"] intValue];

		if(unsavedOption != 2) { // 2 == don't save
			BOOL shouldSave = YES;
			
			if(unsavedOption == 0) { // ask
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
        
        if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJShouldShowPostingConfirmationDialog"] boolValue]) {
            int result = NSRunInformationalAlertPanel(NSLocalizedString(@"Posting Succeeded", @""),
                                                      NSLocalizedString(@"Your entry was sucessfully posted", @""),
                                                      NSLocalizedString(@"OK", @""),
                                                      NSLocalizedString(@"Open Recent Entries", @""),
                                                      nil);
            if(result == NSAlertAlternateReturn)
                [[NSWorkspace sharedWorkspace] openURL: [[[self entry] journal] recentEntriesHttpURL]];
        }
        else {
#warning Why is this here?  I have no idea!
            [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.3]];
        }
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark NSWindow Delegate
// ----------------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
    [htmlPreviewWindow orderOut:self];
    [htmlPreviewWindow release];
    return YES;
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark HTML Tools
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

- (IBAction)insertBlockquote:(id)sender { [self genericTagWrapWithStart: @"<blockquote>" andEnd: @"</blockquote>"]; }

- (IBAction)insertBold:(id)sender { [self genericTagWrapWithStart: @"<strong>" andEnd: @"</strong>"]; }

- (IBAction)insertItalic:(id)sender { [self genericTagWrapWithStart: @"<em>" andEnd: @"</em>"]; }

- (IBAction)insertCenter:(id)sender { [self genericTagWrapWithStart: @"<center>" andEnd: @"</center>"]; }

- (IBAction)insertUnderline:(id)sender { [self genericTagWrapWithStart: @"<u>" andEnd: @"</u>"]; }

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

#warning We could really clean this up!
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

- (void)insertStringAtSelection:(NSString *)newString { [[[self window] firstResponder] insertText: newString]; }

- (void) insertGlossaryText: (NSNotification *)note { [self insertStringAtSelection: [note object]]; }

// Button enablers for User and comm sheets
- (IBAction)enableOKButton:(id)sender
{
    if(currentSheet == userSheet)
        [user_OKButton setEnabled: [[sender stringValue] length] > 0];
    else if(currentSheet == commSheet)
        [comm_OKButton setEnabled: [[sender stringValue] length] > 0];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Validate HTML menu menu items
// ----------------------------------------------------------------------------------------
- (BOOL)validateMenuItem:(id <NSMenuItem>)item {
	return YES;
}

- (BOOL)validateToolbarItem:(id)item
{
    
    if([[item itemIdentifier] isEqualToString: kEditPostItemIdentifier] || [[item itemIdentifier] isEqualToString: kEditPostAndDiscardItemIdentifier])
        if(![[XJAccountManager defaultManager] loggedInAccount])
            return NO;
    
    return YES;
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Community and user combo box data source
// ----------------------------------------------------------------------------------------
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    LJAccount *acct = [[XJAccountManager defaultManager] loggedInAccount];

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
    LJAccount *acct = [[XJAccountManager defaultManager] loggedInAccount];
    
    if(aComboBox == user_nameCombo)
        return [[[acct friendArray] objectAtIndex: index] username];
    else if(aComboBox == comm_nameCombo) {
        return [[[acct joinedCommunityArray] objectAtIndex: index] username];
    }
    return @"";
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Drawer handling
// ----------------------------------------------------------------------------------------
- (IBAction)setValueForSender:(id)sender
{
    if([sender isEqualTo: security]) {
        [[self entry] setSecurityMode: [[sender selectedItem] tag]];
        [friendsTable reloadData];
    }
    else if([sender isEqualTo: userpic]) {
        // Set the user picture
        [userPicView setImage: [XJPreferences imageForURL: [[sender selectedItem] representedObject]]];
        [[self entry] setPictureKeyword: [sender title]];
    }
    else if([sender isEqualTo: preformattedChk]) {
        [[self entry] setOptionPreformatted:[sender state]];
        [self updatePreviewWindow: [[self entry] content]];
    }
    else if([sender isEqualTo: noCommentsChk]) {
        [[self entry] setOptionNoComments: [sender state]];
    }
    else if([sender isEqualTo: backdatedChk]) {
        [[self entry] setOptionBackdated: [sender state]];
        [backdateField setEnabled: [sender state]];

    }
    else if([sender isEqualTo: noEmailChk]) {
        [[self entry] setOptionNoEmail:[sender state]];
    }
    else if([sender isEqualTo: backdateField]) {
        NSString *enteredString = [sender stringValue];
        NSDate *date = [NSDate dateWithNaturalLanguageString: enteredString];
        [[self entry] setDate: date];
    }
}

- (IBAction)toggleDrawer: (id)sender { [drawer toggle: sender]; }

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark NSTableDataSource - friend group security
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if([[XJAccountManager defaultManager] loggedInAccount])
        return [[[[XJAccountManager defaultManager] loggedInAccount] groupArray] count];
    
    return 1;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if([[XJAccountManager defaultManager] loggedInAccount]) 
    {
        NSArray *groups = [[[XJAccountManager defaultManager] loggedInAccount] groupArray];
        if([groups count] > 0) {
            LJGroup *rowGroup = [groups objectAtIndex: rowIndex];

            if([[aTableColumn identifier] isEqualToString: @"name"])
                return [rowGroup name];
            else {
                if([[self entry] accessAllowedForGroup: rowGroup])
                    return [NSNumber numberWithInt: 1];
                else
                    return [NSNumber numberWithInt: 0];
            }
        }
    }
    else {
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return @"(not logged in)";
        else
            return [NSNumber numberWithInt: 0];
    }
    return 0;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSArray *groups = [[[XJAccountManager defaultManager] loggedInAccount] groupArray];
    LJGroup *rowGroup = [groups objectAtIndex: rowIndex];

    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [[self entry] setAccessAllowed: [anObject boolValue] forGroup: rowGroup];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"check"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [aCell setEnabled: [[self entry] securityMode] == LJGroupSecurityMode];
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark HTML Preview
// ----------------------------------------------------------------------------------------
- (IBAction)showPreviewWindow: (id)sender
{
    if(!htmlPreviewWindow) {
        [NSBundle loadNibNamed:@"HTMLPreview" owner: self];
    }

    [htmlPreviewWindow makeKeyAndOrderFront: sender];
    [self updatePreviewWindow: [[self entry] content]];
}

- (NSWindow *)htmlPreviewWindow { return htmlPreviewWindow; }
- (WebView *)htmlPreview { return htmlPreview; }

- (void)updatePreviewWindow: (NSString *)textContent
{
    if([self htmlPreviewWindow] && [[self htmlPreviewWindow] isVisible]) {
        textContent = [textContent translateLJUser];
        textContent = [textContent translateLJComm];
        textContent = [textContent translateLJCutOpenTagWithText];
        textContent = [textContent translateBasicLJCutOpenTag];
        textContent = [textContent translateLJCutCloseTag];
       
        if(![[self entry] optionPreformatted])
            textContent = [textContent translateNewLines];
        
        textContent = [NSString stringWithFormat: @"<html><head><style type=\"text/css\">.xjljcut { background-color: #CCFFFF; padding-top: 5px; padding-bottom: 5px }</style></head><body>%@</body</html>", textContent];
        [[htmlPreview mainFrame] loadHTMLString: textContent  baseURL: nil];
    }
}

- (void)previewUpdateTimerFired: (NSTimer *)aTimer {
	[previewUpdateTimer invalidate];
	[previewUpdateTimer release];
	previewUpdateTimer = nil;
	
	[self updatePreviewWindow: [[self entry] content]];
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


#pragma mark -
#pragma mark iVar Accessors
//=========================================================== 
//  entry 
//=========================================================== 
- (LJEntry *)entry {
    return entry; 
}
- (void)setEntry:(LJEntry *)anEntry {
    [entry release];
    entry = [anEntry retain];
}
@end

#pragma mark -
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
@end
