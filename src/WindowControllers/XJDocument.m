//
//  XJDocument.m
//  Xjournal
//
//  Created by Fraser Speirs on Sat Jan 11 2003.
//  Copyright (c) 2003 Fraser Speirs. All rights reserved.
//

#import "XJDocument.h"
#import "XJPreferences.h"
#import "LJEntryExtensions.h"
#import "XJAccountManager.h"
#import "NSString+Extensions.h"
#import "XJMusic.h"
#import "NSString+Templating.h"
#import "XJDocument+NSToolbarController.h"

#import "Xjournal-Swift.h"

#define DOC_TEXT @"document.text"
#define DOC_SUBJECT @"document.subject"

NSString *TXJshowLocationField = @"ShowLocationField";
NSString *TXJshowMusicField	   = @"ShowMusicField";
NSString *TXJshowTagsField     = @"ShowTagsField";
NSString *TXJshowMoodField     = @"ShowMoodField";

@interface XJDocument ()
@property (readonly) BOOL iTunesIsRunning;
@property (readonly) BOOL iTunesIsPlaying;
@end

@implementation XJDocument
{
    NSArray *nibObjects;
}
@synthesize currentMusic;
@synthesize entryHasBeenPosted;
@synthesize friendArray;
@synthesize joinedCommunityArray;
@synthesize entry;
@synthesize htmlPreview;
@synthesize htmlPreviewWindow;

#pragma mark -
#pragma mark Initialisation
+ (void)initialize {
    NSDictionary *values = @{TXJshowLocationField: @YES,
                             TXJshowMusicField: @YES,
                             TXJshowTagsField: @YES,
                             TXJshowMoodField: @YES};
    
	[[NSUserDefaults standardUserDefaults] registerDefaults:values];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.entry = [[LJEntry alloc] init];
        nibObjects = [[NSArray alloc] init];
        
        if ([[XJAccountManager defaultManager] loggedInAccount]) {
            [[self entry] setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];
        }
        
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:30];
        
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleUIChange)
                                                     name: XJUIChanged
                                                   object:nil];
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                            selector: @selector(iTunesChangedTrack:)
                                                                name: @"com.apple.iTunes.playerInfo"
                                                              object: nil
                                                  suspensionBehavior: NSNotificationSuspensionBehaviorDrop];
    }
    
    return self;
}

- (instancetype)initWithEntry: (LJEntry *)newentry
{
    if (self = [self init]) {
        self.entry = newentry;
    }
    return self;
}

- (void)prepareUI {
    NSToolbar *toolbar;
	
    // Set up NSToolbar
	toolbar = [[NSToolbar alloc] initWithIdentifier: kEditWindowToolbarIdentifier];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
	
    // Configure the table
    NSButtonCell *tPrototypeCell = [[NSButtonCell alloc] initTextCell: @""];
    [tPrototypeCell setEditable: YES];
    [tPrototypeCell setButtonType:NSSwitchButton];
    [tPrototypeCell setImagePosition:NSImageOnly];
    [tPrototypeCell setControlSize:NSSmallControlSize];
	
    [[friendsTable tableColumnWithIdentifier: @"check"] setDataCell: tPrototypeCell];
	
    if([[self entry] itemID] == 0) {
        // Item hasn't been posted, apply default security mode
        LJSecurityMode securityLevel = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJDefaultSecurityLevel"] integerValue];
        [security selectItemAtIndex: [security indexOfItemWithTag: securityLevel]];
        [[self entry] setSecurityMode:securityLevel];
        // Item hasn't been posted, apply default comment screening mode
        int commentScreeningLevel = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJDefaultCommentScreeningLevel"] intValue];
		[commentScreening selectItemAtIndex:commentScreeningLevel];
		switch (commentScreeningLevel) {
			case 1:
				[[self entry] setOptionScreenReplies:@"N"]; // Allow all replies
				break;
			case 2:
				[[self entry] setOptionScreenReplies:@"R"]; // Screen anonymous
				break;
			case 3:
				[[self entry] setOptionScreenReplies:@"F"]; // Allow friends only
				break;
			case 4:
				[[self entry] setOptionScreenReplies:@"A"]; // Screen all
				break;
		}
    } else {
        [security selectItemAtIndex: [security indexOfItemWithTag: [[self entry] securityMode]]];
		unichar screeningChar = [[self entry] optionScreenReplies];
		if (screeningChar == 'A') {
			[commentScreening selectItemAtIndex:4];         // Screen all
		} else if (screeningChar == 'F') {
			[commentScreening selectItemAtIndex:3];         // Allow friends only
		} else if (screeningChar == 'R') {
			[commentScreening selectItemAtIndex:2];         // Screen anonymous
		} else if (screeningChar == 'N') {
			[commentScreening selectItemAtIndex:1];         // Allow all replies
		} else {
			[commentScreening selectItemAtIndex:0];         // Journal default
		}
    }

	// Initially set all items to on
	[theMusicMenuItem setState:NSOnState];
	[theLocationMenuItem setState:NSOnState];
	[theTagsMenuItem setState:NSOnState];
	[theMoodMenuItem setState:NSOnState];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMusicField"]) {
		[self showMusicField:NO];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowLocationField"]) {
		[self showLocationField:NO];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowTagsField"]) {
		[self showTagsField:NO];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMoodField"]) {
		[self showMoodField:NO];
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
		[self buildTagsPopup];
        [userpic setMenu: [[[XJAccountManager defaultManager] loggedInAccount] userPicturesMenu]];
        [userPicView setImage: [XJPreferences imageForURL: [[userpic selectedItem] representedObject]]];
    } else {
        [journalPop setEnabled: NO];
        [moods setEnabled: NO];
        [userpic setEnabled: NO];
        [security setEnabled: NO];
        [tagsPop setEnabled: NO];
    }
	
    // Sync the UI up to the state of the Entry object
    if([[self entry] currentMusic] != nil) {
        [theMusicField setStringValue: [[self entry] currentMusic]];
    } else {
        if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJMusicShouldAutoDetect"] boolValue] &&
		   [[self entry] itemID] == 0)
		{
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
    
    if([[self entry] currentLocation] != nil) {
        [theLocationField setStringValue: [[self entry] currentLocation]];
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
	if(storedSizeString != nil)
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

    journalPop.enabled = YES;
    moods.enabled = YES;
    userpic.enabled = YES;
    security.enabled = YES;
    tagsPop.enabled = YES;

    [[self entry] setJournal: [[[XJAccountManager defaultManager] loggedInAccount] defaultJournal]];

    // If User and Community sheets are laoded, reload their combo boxes
    if(userSheet)
        [user_nameCombo reloadData];

    if(commSheet)
        [comm_nameCombo reloadData];

    [friendsTable reloadData];
	[self buildTagsPopup];
    
    [statusField setStringValue: [NSString stringWithFormat: @"Logged in as %@", [[[XJAccountManager defaultManager] loggedInAccount] username]]];
}

// If an account was deleted
- (void)accountDeleted: (NSNotification *)note
{
	[[self entry] setJournal: nil];
	[self prepareUI];
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self setFriendArray: nil];
    [self setJoinedCommunityArray: nil];
	
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

- (NSWindow *)window { return [[self windowControllers][0] window]; }

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [self prepareUI];
    [super windowControllerDidLoadNib:aController];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Code to show/hide textfields
// ----------------------------------------------------------------------------------------
- (void)handleUIChange
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMusicField"] && [theMusicField frame].size.height > 0.0) {
		[self showMusicField:NO];
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMusicField"] && [theMusicField frame].size.height < 22.0) {
		[self showMusicField:YES];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowLocationField"] && [theLocationField frame].size.height > 0.0) {
		[self showLocationField:NO];
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowLocationField"] && [theLocationField frame].size.height < 22.0) {
		[self showLocationField:YES];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowTagsField"] && [theTagField frame].size.height > 0.0) {
		[self showTagsField:NO];
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowTagsField"] && [theTagField frame].size.height < 22.0) {
		[self showTagsField:YES];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMoodField"] && [theMoodNameField frame].size.height > 0.0) {
		[self showMoodField:NO];
	} else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowMoodField"] && [theMoodNameField frame].size.height < 22.0) {
		[self showMoodField:YES];
	}
}

- (void)moveLocationControls:(signed int)distance
{
	[theLocationFieldLabel setFrameOrigin:NSMakePoint([theLocationFieldLabel frame].origin.x, [theLocationFieldLabel frame].origin.y+distance )];
	[theLocationField setFrameOrigin:NSMakePoint([theLocationField frame].origin.x, [theLocationField frame].origin.y+distance )];
}

- (void)moveMusicControls:(signed int)distance
{
	[theMusicFieldLabel setFrameOrigin:NSMakePoint([theMusicFieldLabel frame].origin.x, [theMusicFieldLabel frame].origin.y+distance )];
	[theMusicField setFrameOrigin:NSMakePoint([theMusicField frame].origin.x, [theMusicField frame].origin.y+distance )];
}

- (void)moveTagsControls:(signed int)distance
{
	[theTagFieldLabel setFrameOrigin:NSMakePoint([theTagFieldLabel frame].origin.x, [theTagFieldLabel frame].origin.y+distance )];
	[theTagField setFrameOrigin:NSMakePoint([theTagField frame].origin.x, [theTagField frame].origin.y+distance )];
	[theTagPopLabel setFrameOrigin:NSMakePoint([theTagPopLabel frame].origin.x, [theTagPopLabel frame].origin.y+distance )];
	[tagsPop setFrameOrigin:NSMakePoint([tagsPop frame].origin.x, [tagsPop frame].origin.y+distance )];
}

- (void)moveMoodControls:(signed int)distance
{
	[theMoodComboLabel setFrameOrigin:NSMakePoint([theMoodComboLabel frame].origin.x, [theMoodComboLabel frame].origin.y+distance )];
	[moods setFrameOrigin:NSMakePoint([moods frame].origin.x, [moods frame].origin.y+distance )];
	[theMoodFieldLabel setFrameOrigin:NSMakePoint([theMoodFieldLabel frame].origin.x, [theMoodFieldLabel frame].origin.y+distance )];
	[theMoodNameField setFrameOrigin:NSMakePoint([theMoodNameField frame].origin.x, [theMoodNameField frame].origin.y+distance )];
}

- (void)moveJournalStatusControls:(signed int)distance
{
	[thePopMenuButton setFrameOrigin:NSMakePoint([thePopMenuButton frame].origin.x ,[thePopMenuButton frame].origin.y+distance )];
	[theJournalLabel setFrameOrigin:NSMakePoint([theJournalLabel frame].origin.x ,[theJournalLabel frame].origin.y+distance )];
	[journalPop setFrameOrigin:NSMakePoint([journalPop frame].origin.x ,[journalPop frame].origin.y+distance )];
	[statusField setFrameOrigin:NSMakePoint([statusField frame].origin.x ,[statusField frame].origin.y+distance )];
	[spinner setFrameOrigin:NSMakePoint([spinner frame].origin.x ,[spinner frame].origin.y+distance )];
}

- (void)showMusicField:(BOOL)aFlag
{
	[theMusicMenuItem setState:aFlag];
	if (YES == aFlag) {
		[theMusicFieldLabel setFrame:NSMakeRect([theMusicFieldLabel frame].origin.x,
												[theMusicFieldLabel frame].origin.y-22.0,
												[theMusicFieldLabel frame].size.width,
												22.0)];
		[theMusicField setFrame:NSMakeRect([theMusicField frame].origin.x,
										   [theMusicField frame].origin.y-22.0,
										   [theMusicField frame].size.width,
										   22.0)];
		
		// Move everything that is below tags controls
		[self moveLocationControls:-31];
		[self moveTagsControls:-31];
		[self moveMoodControls:-31];
		[self moveJournalStatusControls:-31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height-31.0)];
		[theMusicField setHidden:NO];
	} else {
		[theMusicFieldLabel setFrame:NSMakeRect([theMusicFieldLabel frame].origin.x,
												[theMusicFieldLabel frame].origin.y+[theMusicFieldLabel frame].size.height,
												[theMusicFieldLabel frame].size.width,
												0.0)];
		[theMusicField setFrame:NSMakeRect([theMusicField frame].origin.x,
										   [theMusicField frame].origin.y+[theMusicField frame].size.height,
										   [theMusicField frame].size.width,
										   0.0)];
		
		// Move everything that is below tags controls
		[self moveLocationControls:31];
		[self moveTagsControls:31];
		[self moveMoodControls:31];
		[self moveJournalStatusControls:31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height+31.0)];
		[theMusicField setHidden:YES];
	}
	[[NSUserDefaults standardUserDefaults] setBool:aFlag forKey:@"ShowMusicField"];
	[fieldsView setNeedsDisplay:YES];
}

- (void)showLocationField:(BOOL)aFlag
{
	[theLocationMenuItem setState:aFlag];
	if (YES == aFlag) {
		[theLocationFieldLabel setFrame:NSMakeRect([theLocationFieldLabel frame].origin.x,
												   [theLocationFieldLabel frame].origin.y-22.0,
												   [theLocationFieldLabel frame].size.width,
												   22.0)];
		[theLocationField setFrame:NSMakeRect([theLocationField frame].origin.x,
											  [theLocationField frame].origin.y-22.0,
											  [theLocationField frame].size.width,
											  22.0)];
		
		// Move everything that is below tags controls
		[self moveTagsControls:-31];
		[self moveMoodControls:-31];
		[self moveJournalStatusControls:-31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height-31.0)];
		[theLocationField setHidden:NO];
	} else {
        theLocationFieldLabel.frame = NSMakeRect([theLocationFieldLabel frame].origin.x,
                                                 [theLocationFieldLabel frame].origin.y+[theLocationFieldLabel frame].size.height,
                                                 [theLocationFieldLabel frame].size.width,
                                                 0.0);
        theLocationField.frame = NSMakeRect([theLocationField frame].origin.x,
                                            [theLocationField frame].origin.y+[theLocationField frame].size.height,
                                            [theLocationField frame].size.width,
                                            0.0);
		
		// Move everything that is below tags controls
		[self moveTagsControls:31];
		[self moveMoodControls:31];
		[self moveJournalStatusControls:31];
		notFieldsView.frameSize = NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height+31.0);
        theLocationField.hidden = YES;
	}
	[[NSUserDefaults standardUserDefaults] setBool:aFlag forKey:@"ShowLocationField"];
	[fieldsView setNeedsDisplay:YES];
}

- (void)showTagsField:(BOOL)aFlag
{
	[theTagsMenuItem setState:aFlag];
	if (YES == aFlag) {
		[theTagFieldLabel setFrame:NSMakeRect([theTagFieldLabel frame].origin.x,
											  [theTagFieldLabel frame].origin.y-22.0,
											  [theTagFieldLabel frame].size.width,
											  22.0)];
		[theTagField setFrame:NSMakeRect([theTagField frame].origin.x,
										 [theTagField frame].origin.y-22.0,
										 [theTagField frame].size.width,
										 22.0)];
		[theTagPopLabel setFrame:NSMakeRect([theTagPopLabel frame].origin.x,
											[theTagPopLabel frame].origin.y-22.0,
											[theTagPopLabel frame].size.width,
											22.0)];
		[tagsPop setFrame:NSMakeRect([tagsPop frame].origin.x,
									 [tagsPop frame].origin.y-26.0,
									 [tagsPop frame].size.width,
									 26.0)];
		
		// Move everything that is below tags controls
		[self moveMoodControls:-31];
		[self moveJournalStatusControls:-31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height-31.0)];
        theTagField.hidden = NO;
        tagsPop.hidden = NO;
	} else {
		[theTagFieldLabel setFrame:NSMakeRect([theTagFieldLabel frame].origin.x,
											  [theTagFieldLabel frame].origin.y+[theTagFieldLabel frame].size.height,
											  [theTagFieldLabel frame].size.width,
											  0.0)];
		[theTagField setFrame:NSMakeRect([theTagField frame].origin.x,
										 [theTagField frame].origin.y+[theTagField frame].size.height,
										 [theTagField frame].size.width,
										 0.0)];
		[theTagPopLabel setFrame:NSMakeRect([theTagPopLabel frame].origin.x,
											[theTagPopLabel frame].origin.y+[theTagPopLabel frame].size.height,
											[theTagPopLabel frame].size.width,
											0.0)];
		[tagsPop setFrame:NSMakeRect([tagsPop frame].origin.x,
									 [tagsPop frame].origin.y+[tagsPop frame].size.height,
									 [tagsPop frame].size.width,
									 0.0)];
		
		// Move everything that is below tags controls
		[self moveMoodControls:31];
		[self moveJournalStatusControls:31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height+31.0)];
        theTagField.hidden = YES;
        tagsPop.hidden = YES;
	}
	[[NSUserDefaults standardUserDefaults] setBool:aFlag forKey:@"ShowTagsField"];
	[fieldsView setNeedsDisplay:YES];
}

- (void)showMoodField:(BOOL)aFlag
{
	[theMoodMenuItem setState:aFlag];
	if (YES == aFlag) {
		[theMoodComboLabel setFrame:NSMakeRect([theMoodComboLabel frame].origin.x,
											   [theMoodComboLabel frame].origin.y-22.0,
											   [theMoodComboLabel frame].size.width,
											   22.0)];
		[moods setFrame:NSMakeRect([moods frame].origin.x,
								   [moods frame].origin.y-26.0,
								   [moods frame].size.width,
								   26.0)];
		[theMoodFieldLabel setFrame:NSMakeRect([theMoodFieldLabel frame].origin.x,
											   [theMoodFieldLabel frame].origin.y-22.0,
											   [theMoodFieldLabel frame].size.width,
											   22.0)];
		[theMoodNameField setFrame:NSMakeRect([theMoodNameField frame].origin.x,
											  [theMoodNameField frame].origin.y-22.0,
											  [theMoodNameField frame].size.width,
											  22.0)];
		
		// Move everything that is below tags controls
		[self moveJournalStatusControls:-31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height-31.0)];
		[theMoodNameField setHidden:NO];
		[moods setHidden:NO];
	} else {
		[theMoodComboLabel setFrame:NSMakeRect([theMoodComboLabel frame].origin.x,
											   [theMoodComboLabel frame].origin.y+[theMoodComboLabel frame].size.height,
											   [theMoodComboLabel frame].size.width,
											   0.0)];
		[moods setFrame:NSMakeRect([moods frame].origin.x,
								   [moods frame].origin.y+[moods frame].size.height,
								   [moods frame].size.width,
								   0.0)];
		[theMoodFieldLabel setFrame:NSMakeRect([theMoodFieldLabel frame].origin.x,
											   [theMoodFieldLabel frame].origin.y+[theMoodFieldLabel frame].size.height,
											   [theMoodFieldLabel frame].size.width,
											   0.0)];
		[theMoodNameField setFrame:NSMakeRect([theMoodNameField frame].origin.x,
											  [theMoodNameField frame].origin.y+[theMoodNameField frame].size.height,
											  [theMoodNameField frame].size.width,
											  0.0)];
		
		// Move everything that is below tags controls
		[self moveJournalStatusControls:31];
		[notFieldsView setFrameSize:NSMakeSize([notFieldsView frame].size.width, [notFieldsView frame].size.height+31.0)];
		[theMoodNameField setHidden:YES];
		[moods setHidden:YES];
	}
	[[NSUserDefaults standardUserDefaults] setBool:aFlag forKey:@"ShowMoodField"];
	[fieldsView setNeedsDisplay:YES];
}

- (IBAction)musicMenuItemClicked:(id)sender
{
	if ([theMusicField frame].size.height > 0.0) {
		// Shrinks music
		[self showMusicField:NO];
	} else {
		[self showMusicField:YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:XJUIChanged object:self];
}

- (IBAction)locationMenuItemClicked:(id)sender
{
	if ([theLocationField frame].size.height > 0.0) {
		[self showLocationField:NO];
	} else {
		[self showLocationField:YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:XJUIChanged object:self];
}

- (IBAction)tagsMenuItemClicked:(id)sender
{
	if ([theTagField frame].size.height > 0.0) {
		// Shrinks tags
		[self showTagsField:NO];
	} else {
		[self showTagsField:YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:XJUIChanged object:self];
}

- (IBAction)moodMenuItemClicked:(id)sender
{
	if ([theMoodNameField frame].size.height > 0.0) {
		// Shrinks tags
		[self showMoodField:NO];
	} else {
		[self showMoodField:YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:XJUIChanged object:self];
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
        moods.dataSource = acct.moods;
        [moods reloadData];
    }
}

- (void)buildTagsPopup
{
	NSMutableArray *tagArray = [[[self entry] journal] tags];
	[tagsPop removeAllItems];
	if ([tagArray count] == 0) {
		[tagsPop addItemWithTitle:@"(no tags found)"];
        tagsPop.enabled = NO;
	}
	else {
		[tagsPop addItemWithTitle:@"(select tag)"];
		[tagsPop addItemsWithTitles:tagArray];
        tagsPop.enabled = YES;
	}
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Saving
// ----------------------------------------------------------------------------------------
-(BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    BOOL isSuccess = [[self entry] writePropertyListToFile: [url path] atomically: YES];
    if (isSuccess) {
        *outError = nil;
    } else {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorUnsupportedURL userInfo:nil];
    }
    return isSuccess;
}

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    [self setEntry: [[LJEntry alloc] init]];
    [[self entry] configureWithContentsOfFile: [url path]];
    *outError = nil;
    return YES;
}

#if 0
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
    return [[self entry] writePropertyListToFile: fileName atomically: YES];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    [self setEntry: [[LJEntry alloc] init]];
	[[self entry] configureWithContentsOfFile: fileName];
    return YES;
}
#endif

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
			previewUpdateTimer = nil;
		}
		previewUpdateTimer = [NSTimer scheduledTimerWithTimeInterval: 1
															   target: self
															 selector: @selector(previewUpdateTimerFired:)
															 userInfo: nil
															  repeats: NO];
    }
}

// This enables shift-tab out of the textfield into the subject field :-)
// See: http://www.omnigroup.com/mailman/archive/macosx-dev/2001-March/022693.html
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

        [[self entry] setCurrentMusic: [[aNotification object] stringValue]];        
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Popup Menu targets
// ----------------------------------------------------------------------------------------
- (IBAction)setSelectedJournal:(id)sender {
    [[self entry] setJournal: [[sender selectedItem] representedObject]];
	LJJournal *j = [[self entry] journal];
	if ([j tags] == nil) {
		NSDictionary *tagsReply = [j getTagsReplyForThisJournal];
		[j createJournalTagsArray: tagsReply];
	}
	[self buildTagsPopup]; // rebuild the tags dropdown when the journal changes
}

- (IBAction)setSelectedMood:(id)sender {
    [[self entry] setCurrentMood: [sender stringValue]];
	[[self entry] setCurrentMoodName: [sender stringValue]];
}

- (IBAction)addSelectedTag:(id)sender {
	if ([sender indexOfSelectedItem] != 0) {
		[[self entry] addTag: [sender titleOfSelectedItem]];
	}
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Music Detection
// ----------------------------------------------------------------------------------------
- (IBAction)detectMusicNow:(id)sender {
	[self setCurrentMusic: [XJMusic currentMusic]];
}

- (void)iTunesChangedTrack: (NSNotification *)note {
	if([[NSUserDefaults standardUserDefaults] boolForKey: @"XJDetectMusicOniTunesTrackChange"])
		[self detectMusicNow: self];
}

//=========================================================== 
//  currentMusic 
//=========================================================== 
- (XJMusic *)currentMusic {
    return currentMusic; 
}
- (void)setCurrentMusic:(XJMusic *)aCurrentMusic {
    currentMusic = aCurrentMusic;
	NSString *formatString = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey: @"XJMusicSubstitutionString"];
	
	if(currentMusic != nil) {
		[[self entry] setCurrentMusic: [formatString stringByParsingTagsWithStartDelimeter: @"<$"
																			  endDelimeter: @"/>"
																			   usingObject: [self currentMusic]]];
	}
	else {
		[[self entry] setCurrentMusic: [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey: @"XJNoMusicString"]];
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
                                           NSLocalizedString(@"Your entry was successfully posted", @""));
        }
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertAlternateReturn)
    {
        [[NSWorkspace sharedWorkspace] openURL: [[[self entry] journal] recentEntriesHttpURL]];  
    }
    [self closeHTMLPreviewWindow];
    [self close];
}

- (BOOL)postEntryAndReturnStatus
{
    BOOL isPosted = ([[self entry] itemID] != 0);
    XJMusic *tempMusic;

    // Force the first responder to end editing
    [[self window] endEditingFor:nil];

    /* Check if the user wants iTMS links instead of current music.
        Also, only do this if this isn't a repost. 
        
        Consider, also, the case where the user has entered 
        music text by themselves instead of getting it via the button.
    
        Also, if we detected iTMS links, but the user has since cleared 
        the music field, we don't want to do anything.
    */
    if(![[self entry] itemID] &&
	   [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJGenerateiTunesLinks"] boolValue] &&
	   [self currentMusic]) {
        [[self entry] setCurrentMusic: nil];
		tempMusic = [XJMusic musicAsiTunesLink:currentMusic];
        [[self entry] setContent: [NSString stringWithFormat: @"%@\n\n%@%@", [[self entry] content], @"<a href=\"http://www.itunes.com\"><img src=\"http://ax.phobos.apple.com.edgesuite.net/images/iTunes.gif\" border=\"0\"></a>&nbsp;", tempMusic]];
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
        @try {
            [[self entry] saveToJournal];
        } @catch (NSException *localException) {
            NSBeginCriticalAlertSheet([localException name], @"OK", nil, nil,
                                      [self window], nil, nil, nil, nil,
                                      @"%@", [localException reason]);
            [spinner stopAnimation: self];    
            return NO;
        }

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
	if([self fileURL] != nil && [self isDocumentEdited]) {  // Was opened from file and is dirty
		NSInteger unsavedOption = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJUnsavedOption"] integerValue];

		if(unsavedOption != 2) { // 2 == don't save
			BOOL shouldSave = YES;
			
			if(unsavedOption == 0) { // ask
				NSString *file = [[self fileURL] lastPathComponent];
				NSString *msg = [NSString stringWithFormat: @"Do you want to save the changes you made in the document \"%@\"?", file];

				NSInteger result = NSRunInformationalAlertPanel(msg,
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
        
        if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJShouldShowPostingConfirmationDialog"] boolValue]) {
            NSBeginInformationalAlertSheet(NSLocalizedString(@"Posting Succeeded", @""),
                                           NSLocalizedString(@"OK", @""),
                                           NSLocalizedString(@"Open Recent Entries", @""),
                                           nil, /* Other Btn */
                                           [self window],
                                           self, /* id modalDelegate */
                                           @selector(sheetDidEnd:returnCode:contextInfo:), /* SEL didEndSelector */
                                           nil, /* SEL didDismissSelector */
                                           nil, /* void *contextInfo */
                                           NSLocalizedString(@"Your entry was successfully posted", @""));
            
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
    return YES;
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark HTML Tools
// ----------------------------------------------------------------------------------------
- (IBAction)insertLink:(id)sender
{
    if(!hrefSheet) {
        NSArray *tempNibArray;
        [[NSBundle mainBundle] loadNibNamed: @"HREFSheet" owner: self topLevelObjects: &tempNibArray];
        nibObjects = [nibObjects arrayByAddingObjectsFromArray: tempNibArray];
    }
    
	NSRange selection = [theTextView selectedRange];

	// Clear href field
	[html_hrefField setStringValue:@""];

    if(selection.length == 0) {
        [html_LinkTextField setStringValue: @""];
		[hrefSheet makeFirstResponder:html_LinkTextField];
    } else {
        NSString *selectedText = [[theTextView string] substringWithRange: selection];
        [html_LinkTextField setStringValue: selectedText];
		[hrefSheet makeFirstResponder:html_hrefField];
    }
	
    [self startSheet: hrefSheet];
}

- (IBAction)pasteLink:(id)sender {
	NSPasteboard *genPboard = [NSPasteboard generalPasteboard];
	if([[genPboard types] containsObject: NSStringPboardType]) {
		NSString *pasteboardString = [genPboard stringForType: NSStringPboardType];
		[self genericTagWrapWithStart: [NSString stringWithFormat: @"<a href=\"%@\">", pasteboardString]
							   andEnd: @"</a>"];
	}
	else {
		NSBeep();	
	}
}

- (IBAction)insertImage:(id)sender
{
    if(!imgSheet) {
        NSArray *tempNibArray;
        [[NSBundle mainBundle] loadNibNamed: @"IMGSheet" owner: self topLevelObjects: &tempNibArray];
        nibObjects = [nibObjects arrayByAddingObjectsFromArray: tempNibArray];
    }

	// Clear fields
	[srcField setStringValue:@""];
	[altField setStringValue:@""];
	[sizeWidth setStringValue:@""];
	[sizeHeight setStringValue:@""];
	[spaceWidth setStringValue:@""];
	[spaceHeight setStringValue:@""];
	[borderSize setStringValue:@""];

    // Make sure we always start in the first textfield of the sheet
	[imgSheet makeFirstResponder:srcField];

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
    if(!cutSheet) {
        NSArray *tempNibArray;
        [[NSBundle mainBundle] loadNibNamed: @"CutSheet" owner: self topLevelObjects: &tempNibArray];
        nibObjects = [nibObjects arrayByAddingObjectsFromArray: tempNibArray];
    }

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
    if(!userSheet) {
        NSArray *tempNibArray;
        [[NSBundle mainBundle] loadNibNamed: @"UserSheet" owner: self topLevelObjects: &tempNibArray];
        nibObjects = [nibObjects arrayByAddingObjectsFromArray: tempNibArray];
    }
    
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
- (BOOL)validateMenuItem:(NSMenuItem*)item {
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
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    LJAccount *acct = [[XJAccountManager defaultManager] loggedInAccount];
	

    if(aComboBox == user_nameCombo) {
		[self setFriendArray:[acct friendArray]];
		return [[self friendArray] count];
    }
    else if(aComboBox == comm_nameCombo) {
		[self setJoinedCommunityArray:[acct joinedCommunityArray]];
		return [[self joinedCommunityArray] count];
    }

    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{    
    if(aComboBox == user_nameCombo)
        return [[self friendArray][index] username];
    else if(aComboBox == comm_nameCombo) {
        return [[self joinedCommunityArray][index] username];
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
        [[self entry] setSecurityMode: (int)[[sender selectedItem] tag]];
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
    else if([sender isEqualTo: commentScreening]) {
		switch ([sender indexOfSelectedItem]) {
			case 1:
				[[self entry] setOptionScreenReplies:@"N"]; // Allow all replies
				break;
			case 2:
				[[self entry] setOptionScreenReplies:@"R"]; // Screen anonymous
				break;
			case 3:
				[[self entry] setOptionScreenReplies:@"F"];	// Allow friends only
				break;
			case 4:
				[[self entry] setOptionScreenReplies:@"A"]; // Screen all
				break;				
		}
    }
}

- (IBAction)toggleDrawer: (id)sender { [drawer toggle: sender]; }

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark NSTableDataSource - friend group security
// ----------------------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if([[XJAccountManager defaultManager] loggedInAccount])
        return [[[[XJAccountManager defaultManager] loggedInAccount] groupArray] count];
    
    return 1;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex
{
    if([[XJAccountManager defaultManager] loggedInAccount]) 
    {
        NSArray *groups = [[[XJAccountManager defaultManager] loggedInAccount] groupArray];
        if([groups count] > 0) {
            LJGroup *rowGroup = groups[rowIndex];

            if([[aTableColumn identifier] isEqualToString: @"name"])
                return [rowGroup name];
            else {
                if([[self entry] accessAllowedForGroup: rowGroup])
                    return @1;
                else
                    return @0;
            }
        }
    }
    else {
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return @"(not logged in)";
        else
            return @0;
    }
    return 0;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *groups = [[[XJAccountManager defaultManager] loggedInAccount] groupArray];
    LJGroup *rowGroup = groups[rowIndex];

    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [[self entry] setAccessAllowed: [anObject boolValue] forGroup: rowGroup];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"check"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [aCell setEnabled: [[self entry] securityMode] == LJSecurityModeGroup];
    }
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark HTML Preview
// ----------------------------------------------------------------------------------------
- (IBAction)showPreviewWindow: (id)sender
{
    if(!htmlPreviewWindow) {
        NSArray *tempNibArray;
        [[NSBundle mainBundle] loadNibNamed: @"HTMLPreview" owner: self topLevelObjects: &tempNibArray];
        nibObjects = [nibObjects arrayByAddingObjectsFromArray: tempNibArray];
    }

    [htmlPreviewWindow makeKeyAndOrderFront: sender];
    [self updatePreviewWindow: [[self entry] content]];
}

- (void)updatePreviewWindow: (NSString *)textContent
{
    if([self htmlPreviewWindow] && [[self htmlPreviewWindow] isVisible]) {
        textContent = [textContent translateLJUser];
        textContent = [textContent translateLJComm];
        textContent = [textContent translateLJCutOpenTagWithText];
        textContent = [textContent translateBasicLJCutOpenTag];
        textContent = [textContent translateLJCutCloseTag];
       
        if(![[self entry] optionPreformatted])
            textContent = [textContent translateNewLinesOutsideTables];
        
        textContent = [NSString stringWithFormat: @"<html><head><style type=\"text/css\">.xjljcut { background-color: #CCFFFF; padding-top: 5px; padding-bottom: 5px }</style></head><body>%@</body</html>", textContent];
        [[htmlPreview mainFrame] loadHTMLString: textContent  baseURL: nil];
    }
}

- (void)previewUpdateTimerFired: (NSTimer *)aTimer {
	[previewUpdateTimer invalidate];
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
    WebNavigationType key = [actionInformation[WebActionNavigationTypeKey] integerValue];
    switch(key){
        case WebNavigationTypeLinkClicked:
            // Since a link was clicked, we want WebKit to ignore it
            [listener ignore];
            // Instead of opening it in the WebView, we want to open
            // the URL in the user's default browser
            [[NSWorkspace sharedWorkspace] openURL: actionInformation[WebActionOriginalURLKey]];
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
- (void)setEntry:(LJEntry *)anEntry {
    entry = anEntry;
	[self setEntryHasBeenPosted: [entry webItemID] != 0];
}

#pragma mark -
- (BOOL) iTunesIsRunning
{
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
	for (NSRunningApplication *app in apps) {
		if ([app.bundleIdentifier isEqualToString:@"com.apple.iTunes"]) {
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

        script = [[NSAppleScript alloc] initWithSource: @"tell application \"iTunes\" to artist of current track"];
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
