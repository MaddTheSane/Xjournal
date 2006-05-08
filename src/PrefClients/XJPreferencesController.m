#import "XJPreferencesController.h"
#import "XJPreferences.h"
#import "CCFSoftwareUpdate.h"
#import "XJAccountManager.h"
#import "XJCheckFriendsSessionManager.h"

// Almost all this code taken from http://www.cocoadev.com/index.pl?MultiPanePreferences

@implementation XJPreferencesController
- (id)init {
	self = [super initWithWindowNibName: @"Preferences"];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
															  forKeyPath: @"values.XJCheckFriendsShouldCheck"
																 options: NSKeyValueObservingOptionNew
																 context: nil];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
															  forKeyPath: @"values.XJCheckFriendsGroupType"
																 options: NSKeyValueObservingOptionNew
																 context: nil];
	
	return self;
}

- (void)windowDidLoad
{
	[self buildSoundMenu];
	
    NSToolbarItem *item;
    items = [[NSMutableDictionary alloc] init];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:@"General"];
    [item setPaletteLabel:@"General"];
    [item setLabel:@"General"];
    [item setToolTip:@"General preference options."];
    [item setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GenPreferences" ofType:@"tiff"]]];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    [items setObject:item forKey:@"General"];
    [item release];

	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"Friends"];
    [item setPaletteLabel:@"Friends"];
    [item setLabel:@"Friends"];
    [item setToolTip:@"Friends preference options."];
    [item setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XJCheckFriendsClient" ofType:@"tiff"]]];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    [items setObject:item forKey:@"Friends"];
    [item release];

	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"Music"];
    [item setPaletteLabel:@"Music"];
    [item setLabel:@"Music"];
    [item setToolTip:@"Music preference options."];
    [item setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cd" ofType:@"icns"]]];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    [items setObject:item forKey:@"Music"];
    [item release];
	
	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"History"];
    [item setPaletteLabel:@"History"];
    [item setLabel:@"History"];
    [item setToolTip:@"History preference options."];
    [item setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"History" ofType:@"tiff"]]];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    [items setObject:item forKey:@"History"];
    [item release];	

	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"Weblogs"];
    [item setPaletteLabel:@"Weblogs"];
    [item setLabel:@"Weblogs"];
    [item setToolTip:@"Weblogs preference options."];
    [item setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PostToWeblog" ofType:@"tif"]]];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    [items setObject:item forKey:@"Weblogs"];
    [item release];
	
	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"SWUpdate"];
    [item setPaletteLabel:@"Software Update"];
    [item setLabel:@"Update"];
    [item setToolTip:@"Software Update preference options."];
    [item setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"OSUPreferences" ofType:@"tiff"]]];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    [items setObject:item forKey:@"SWUpdate"];
    [item release];
	
    //any other items you want to add, do so here.
    //after you are done, just do all the toolbar stuff.
    //[self window] is an outlet pointing to the Preferences Window you made to hold all these custom views.
	
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"preferencePanes"];
    [toolbar setDelegate:self];  //this is how the toolbar knows what can be selected and such.
    [toolbar setAllowsUserCustomization:NO];  //this is just a pref window, so we don't need to allow customization.
    [toolbar setAutosavesConfiguration:NO];  //we just set everything up manually, so no need for this.
    [[self window] setToolbar:toolbar];  //sets the toolbar to "toolbar"
    [toolbar release];  //setToolbar retains the toolbar we pass, so release the one we used.
    [[self window] center];  //center the window. This is how the pref window should act.
    [self switchViews:nil];  //this is just to make it select General by default.
}

//called everytime a toolbar item is cilcked. If nil, return the default ("General").
- (void)switchViews:(NSToolbarItem *)item
{
    NSString *sender;
    if(item == nil){  //set the pane to the default.
        sender = @"General";
        [[[self window] toolbar] setSelectedItemIdentifier:sender];
    }else{
        sender = [item itemIdentifier];
    }
	
    //make a temp pointer.
    //
    // ...and nil it, so we aren't potentially pointing to uninitialized memory 
    // if we somehow fall out the bottom of that if tree below. ;) --sparks
    NSView *prefsView = nil;
	
    //set the title to the name of the Preference Item.
    [[self window] setTitle:sender];
	
    if([sender isEqualToString:@"General"]){
        //assign the temp pointer to the generalView we set up in IB.
        prefsView = accountsView;
    }else if([sender isEqualToString:@"History"]){
        //assign the temp pointer to the searchView we set up in IB.
        prefsView = historyView;
    }else if([sender isEqualToString:@"Friends"]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = friendsView;
    }
	else if([sender isEqualToString:@"Music"]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = musicView;
    }
	else if([sender isEqualToString:@"Weblogs"]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = weblogsView;
    }
	else if([sender isEqualToString:@"SWUpdate"]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = softwareUpdateView;
    }
    
    //to stop flicker, we make a temp blank view.
    NSView *tempView = [[NSView alloc] initWithFrame:[[[self window] contentView] frame]];
    [[self window] setContentView:tempView];
    [tempView release];
    
    //mojo to get the right frame for the new window.
    NSRect newFrame = [[self window] frame];
    newFrame.size.height = [prefsView frame].size.height + ([[self window] frame].size.height - [[[self window] contentView] frame].size.height);
    newFrame.size.width = [prefsView frame].size.width;
    newFrame.origin.y += ([[[self window] contentView] frame].size.height - [prefsView frame].size.height);
    
    //set the frame to newFrame and animate it. (change animate:YES to animate:NO if you don't want this)
    [[self window] setShowsResizeIndicator:YES];
    [[self window] setFrame:newFrame display:YES animate:YES];
    //set the main content view to the new view we have picked through the if structure above.
    [[self window] setContentView:prefsView];
}

//toolbar delegate methods.

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [items objectForKey:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)theToolbar
{
    return [self toolbarDefaultItemIdentifiers:theToolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)theToolbar
{
    //just return an array with all your items.
    return [NSArray arrayWithObjects:@"General", @"Friends", @"Music", @"Weblogs", @"History", @"SWUpdate", nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar
{
    //make all of them selectable. This puts that little grey outline thing around an item when you select it.
    return [items allKeys];
}

#pragma mark -
#pragma mark Font Selector
- (void)changeTextFont:(id)sender
{
	/*
	 The user changed the current font selection, so update the default font
	 */
	
	// Get font name and size from user defaults
	NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
	NSString *fontName = [values valueForKey:@"XJEntryWindowFont"];
	int fontSize = [[values valueForKey:@"XJEntryWindowFontSize"] floatValue];
	
	// Create font from name and size; initialize font panel
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
	if (font == nil)
	{
		font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
	[[NSFontManager sharedFontManager] setSelectedFont:font 
											isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
	
	// Set window as firstResponder so we get changeFont: messages
    [[self window] makeFirstResponder:[self window]];
}

- (void)changeFont:(id)sender
{
	/*
	 This is the message the font panel sends when a new font is selected
	 */
	// Get selected font
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = [fontManager selectedFont];
	if (selectedFont == nil)
	{
		selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
	NSFont *panelFont = [fontManager convertFont:selectedFont];
	
	// Get and store details of selected font
	// Note: use fontName, not displayName.  The font name identifies the font to
	// the system, we use a value transformer to show the user the display name
	NSNumber *fontSize = [NSNumber numberWithFloat:[panelFont pointSize]];	
	
	id currentPrefsValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
	[currentPrefsValues setValue:[panelFont fontName] forKey:@"XJEntryWindowFont"];
	[currentPrefsValues setValue:fontSize forKey:@"XJEntryWindowFontSize"];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Sounds Popup Menu
// ----------------------------------------------------------------------------------------
- (void)buildSoundMenu
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSEnumerator *locs = [[NSArray arrayWithObjects: @"/System/Library/Sounds", [@"~/Library/Sounds" stringByExpandingTildeInPath], nil] objectEnumerator];
    NSString *path;

    NSMenu *menu = [[NSMenu alloc] init];
    
    while(path = [locs nextObject]) {
        NSDirectoryEnumerator *dEnum = [manager enumeratorAtPath: path];
        NSString *file, *baseName;

        while(file = [dEnum nextObject]) {
            NSMenuItem *item;
            if(![file hasPrefix: @"."]) {
                baseName = [[[file lastPathComponent] componentsSeparatedByString: @"."] objectAtIndex: 0];
                item = [[NSMenuItem alloc] initWithTitle: baseName action: @selector(setSelectedFriendsSound:) keyEquivalent: @""];
                [item setTarget: self];
                [item setRepresentedObject: [NSString stringWithFormat: @"%@/%@", path,file]];
                [menu addItem: item];
                [item release];
            }
        }
    }
    [soundSelection setMenu: menu];
    [menu release];
}

- (IBAction)setSelectedFriendsSound:(id)sender {
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [sender representedObject] forKey: @"XJCheckFriendsAlertSound"];
	[[[[NSSound alloc] initWithContentsOfFile: [sender representedObject] byReference: NO] autorelease] play];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark NSTableDataSource - friend group security
// ----------------------------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    if(!acct)
        return 1;
    
    return [[acct groupArray] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    if(!acct) {
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return @"(not logged in)";
        else
            return [NSNumber numberWithInt: 0];
    }
    else {
        NSArray *groups = [acct groupArray];
        LJGroup *rowGroup = [groups objectAtIndex: rowIndex];
		
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return [rowGroup name];
        else {
            // Here return an NSNumber signifying whether the group is being checked for.
            return [NSNumber numberWithBool: [XJPreferences shouldCheckForGroup: rowGroup]];
        }
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    NSArray *groups = [acct groupArray];
    LJGroup *rowGroup = [groups objectAtIndex: rowIndex];
	
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [XJPreferences setShouldCheck: [anObject boolValue] forGroup: rowGroup];
    }
    [aTableView reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"check"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
		id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
		BOOL shouldCheck = [[values valueForKey: @"XJCheckFriendsShouldCheck"] boolValue];
		int checkGroupType = [[values valueForKey: @"XJCheckFriendsGroupType"] intValue];
		
        [aCell setEnabled: (shouldCheck && (acct && checkGroupType == 1))];
    }
}

#pragma mark -
- (IBAction)openAccountWindow: (id)sender
{
    [NSApp sendAction: @selector(showAccountEditWindow:) to: nil from: self];
}

#pragma mark -
#pragma mark Software Update
- (IBAction)checkNow: (id)sender {
    [[CCFSoftwareUpdate sharedUpdateChecker] runSoftwareUpdate: NO];
}

#pragma mark -
#pragma mark Key-Value Observing
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context 
{
	if([keyPath isEqualToString: @"values.XJCheckFriendsShouldCheck"]) {
		int changeKind = [[change objectForKey: NSKeyValueChangeKindKey] intValue];
		if(changeKind == NSKeyValueChangeSetting) {
			
			// Here, we *should* inspect [change objectForKey: NSKeyValueChangeNewKey]
			// But there's a bug in Tiger such that this is always nil.
			// Instead, we'll interrogate the defaults directly.
			// rdar://3777034 apparently.
			
			if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: @"XJCheckFriendsShouldCheck"] boolValue])
				[[XJCheckFriendsSessionManager sharedManager] startCheckingFriends];
			else
				[[XJCheckFriendsSessionManager sharedManager] stopCheckingFriends];
		}
	}
	
	if([keyPath isEqualToString: @"values.XJCheckFriendsGroupType"]) {
		[checkFriendsGroupTable reloadData];
	}
}
@end
