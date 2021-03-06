#import "XJPreferencesController.h"
#import "XJPreferences.h"
#import "XJAccountManager.h"
#import "XJCheckFriendsSessionManager.h"
#import "XJAppDelegate.h"
#import <Sparkle/SUUpdater.h>

#define SUScheduledCheckIntervalKey @"SUScheduledCheckInterval"
#define SUEnableAutomaticChecksKey @"SUEnableAutomaticChecks"

#define EntryFontName @"XJEntryWindowFontName"
#define EntryFontSize @"XJEntryWindowFontSize"

#pragma mark Toolbar identifiers
#define kGeneralID @"General"
#define kFriendsID @"Friends"
#define kMusicID @"Music"
#define kHistoryID @"History"
#define kWeblogsID @"Weblogs"
#define kSWUpdateID @"SWUpdate"
#define kNotificationsID @"NotificationCenter"

// Almost all this code taken from http://www.cocoadev.com/index.pl?MultiPanePreferences

@implementation XJPreferencesController
@synthesize accountsView;
@synthesize musicView;
@synthesize friendsView;
@synthesize historyView;
@synthesize weblogsView;
@synthesize softwareUpdateView;
- (instancetype)init {
    if (self = [super initWithWindowNibName: @"Preferences"]) {
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
                                                                  forKeyPath: @"values."XJCheckFriendsShouldCheck
                                                                     options: NSKeyValueObservingOptionNew
                                                                     context: nil];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver: self
                                                                  forKeyPath: @"values."CHECKFRIENDS_GROUP_TYPE
                                                                     options: NSKeyValueObservingOptionNew
                                                                     context: nil];
    }
    
    return self;
}

- (void)windowDidLoad
{
	[self buildSoundMenu];
	
    NSToolbarItem *item;
    items = [[NSMutableDictionary alloc] init];
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:kGeneralID];
    [item setPaletteLabel:@"General"];
    [item setLabel:@"General"];
    [item setToolTip:@"General preference options."];
    NSImage *genImage = [NSImage imageNamed: NSImageNamePreferencesGeneral];
    [item setImage:genImage];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    items[kGeneralID] = item;

	item = [[NSToolbarItem alloc] initWithItemIdentifier:kFriendsID];
    [item setPaletteLabel:@"Friends"];
    [item setLabel:@"Friends"];
    [item setToolTip:@"Friends preference options."];
    NSImage *friendsImage = [NSImage imageNamed: NSImageNameUserGroup];
    [item setImage:friendsImage];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    items[kFriendsID] = item;

	item = [[NSToolbarItem alloc] initWithItemIdentifier:kMusicID];
    [item setPaletteLabel:@"Music"];
    [item setLabel:@"Music"];
    [item setToolTip:@"Music preference options."];
    NSImage *musicImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericCDROMIcon)];
    [item setImage:musicImage];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    items[kMusicID] = item;
	
	item = [[NSToolbarItem alloc] initWithItemIdentifier:kHistoryID];
    [item setPaletteLabel:@"History"];
    [item setLabel:@"History"];
    [item setToolTip:@"History preference options."];
    NSImage *historyImage = [NSImage imageNamed: @"History"];
    [item setImage:historyImage];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    items[kHistoryID] = item;

	item = [[NSToolbarItem alloc] initWithItemIdentifier:kWeblogsID];
    [item setPaletteLabel:@"Weblogs"];
    [item setLabel:@"Weblogs"];
    [item setToolTip:@"Weblogs preference options."];
    NSImage *weblogsImage = [NSImage imageNamed: @"PostToWeblog"];
    [item setImage:weblogsImage];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    items[kWeblogsID] = item;
	
	item = [[NSToolbarItem alloc] initWithItemIdentifier:kSWUpdateID];
    [item setPaletteLabel:@"Software Update"];
    [item setLabel:@"Update"];
    [item setToolTip:@"Software Update preference options."];
    NSImage *updateImage = [NSImage imageNamed: @"OSUPreferences"];
    [item setImage:updateImage];
    [item setTarget:self];
    [item setAction:@selector(switchViews:)];
    items[kSWUpdateID] = item;
    
    item = [[NSToolbarItem alloc] initWithItemIdentifier:kNotificationsID];
    item.paletteLabel = @"Notification Center";
    item.label = @"Notifications";
    item.toolTip = @"Configure what shows up in Notification Center";
    //TODO: find image
    //item.image;
    item.target = self;
    item.action = @selector(switchViews:);
    items[kNotificationsID] = item;
	
    //any other items you want to add, do so here.
    //after you are done, just do all the toolbar stuff.
    //[self window] is an outlet pointing to the Preferences Window you made to hold all these custom views.
	
	NSInteger checkInterval = [[NSUserDefaults standardUserDefaults] integerForKey:SUScheduledCheckIntervalKey];
	if (checkInterval == 0) {
        [updateCheckSelection selectItemWithTag:1]; //Never
	} else if (checkInterval == 24*60*60) {
        [updateCheckSelection selectItemWithTag:2]; //Daily
	} else if (checkInterval == 7*24*60*60) {
        [updateCheckSelection selectItemWithTag:3]; //Weekly
	} else if (checkInterval == 4*7*24*60*60) {
        [updateCheckSelection selectItemWithTag:4]; //Monthly
	} else {
		// If it isn't one of these values then pick a default
        [updateCheckSelection selectItemWithTag:3]; //Weekly
	}
	
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"preferencePanes"];
    [toolbar setDelegate:self];  //this is how the toolbar knows what can be selected and such.
    [toolbar setAllowsUserCustomization:NO];  //this is just a pref window, so we don't need to allow customization.
    [toolbar setAutosavesConfiguration:NO];  //we just set everything up manually, so no need for this.
    [[self window] setToolbar:toolbar];  //sets the toolbar to "toolbar"
      //setToolbar retains the toolbar we pass, so release the one we used.
    [[self window] center];  //center the window. This is how the pref window should act.
    [self switchViews:nil];  //this is just to make it select General by default.
}

//called everytime a toolbar item is cilcked. If nil, return the default ("General").
- (void)switchViews:(NSToolbarItem *)item
{
    NSString *sender;
    if(item == nil){  //set the pane to the default.
        sender = kGeneralID;
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
	
    if([sender isEqualToString:kGeneralID]){
        //assign the temp pointer to the generalView we set up in IB.
        prefsView = accountsView;
    }else if([sender isEqualToString:kHistoryID]){
        //assign the temp pointer to the searchView we set up in IB.
        prefsView = historyView;
    }else if([sender isEqualToString:kFriendsID]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = friendsView;
    }
	else if([sender isEqualToString:kMusicID]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = musicView;
    }
	else if([sender isEqualToString:kWeblogsID]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = weblogsView;
    }
	else if([sender isEqualToString:kSWUpdateID]){
        //assign the temp pointer to the appearanceView we set up in IB.
        prefsView = softwareUpdateView;
    } else if ([sender isEqualToString:kNotificationsID]) {
        prefsView = _notificationsView;
    }
    
    //to stop flicker, we make a temp blank view.
    NSView *tempView = [[NSView alloc] initWithFrame:[[[self window] contentView] frame]];
    [[self window] setContentView:tempView];
    
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
    return items[itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)theToolbar
{
    return [self toolbarDefaultItemIdentifiers:theToolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)theToolbar
{
    //just return an array with all your items.
    return @[kGeneralID, kFriendsID, kMusicID, kWeblogsID, kHistoryID, kSWUpdateID, kNotificationsID];
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
	NSUserDefaults *values = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [values valueForKey:EntryFontName];
	CGFloat fontSize = [values floatForKey:EntryFontSize];
	
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
	NSNumber *fontSize = @([panelFont pointSize]);
	
	id currentPrefsValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
	[currentPrefsValues setValue:[panelFont fontName] forKey:EntryFontName];
	[currentPrefsValues setValue:fontSize forKey:EntryFontSize];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark Sounds Popup Menu
// ----------------------------------------------------------------------------------------
// Code taken from Transmission
- (NSArray *) sounds
{
    NSMutableArray * sounds = [[NSMutableArray alloc] init];
    
    NSArray * directories = NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory, NSAllDomainsMask, YES);
    
    for (__strong NSString * directory in directories) {
        directory = [directory stringByAppendingPathComponent: @"Sounds"];
        
        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath: directory isDirectory: &isDirectory] && isDirectory) {
            NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: directory error: NULL];
            for (NSString * sound in directoryContents) {
                NSString *asound = [sound stringByDeletingPathExtension];
                if ([NSSound soundNamed: asound]) {
                    [sounds addObject: [directory stringByAppendingPathComponent:sound]];
                }
            }
        }
    }
    
    return sounds;
}

- (void)buildSoundMenu
{
    NSArray *aSounds = [[self sounds] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1 = [obj1 lastPathComponent];
        NSString *str2 = [obj2 lastPathComponent];
        
        return [str1 localizedStandardCompare:str2];
    }];
    NSMenu *menu = [[NSMenu alloc] init];
    
    for (NSString *path in aSounds) {
        NSString *baseName = [[path lastPathComponent] stringByDeletingPathExtension];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: baseName action: @selector(setSelectedFriendsSound:) keyEquivalent: @""];
        item.target = self;
        item.representedObject = path;
        [menu addItem: item];
    }
    [soundSelection setMenu: menu];
}

- (IBAction)setSelectedFriendsSound:(id)sender {
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [sender representedObject] forKey: CHECKFRIENDS_SELECTED_SOUND];
	[[[NSSound alloc] initWithContentsOfFile: [sender representedObject] byReference: NO] play];
}

// ----------------------------------------------------------------------------------------
#pragma mark -
#pragma mark NSTableDataSource - friend group security
// ----------------------------------------------------------------------------------------
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    if(!acct)
        return 1;
    
    return [[acct groupArray] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    if(!acct) {
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return @"(not logged in)";
        else
            return @0;
    }
    else {
        NSArray *groups = [acct groupArray];
        LJGroup *rowGroup = groups[rowIndex];
		
        if([[aTableColumn identifier] isEqualToString: @"name"])
            return [rowGroup name];
        else {
            // Here return an NSNumber signifying whether the group is being checked for.
            return @([XJPreferences shouldCheckForGroup: rowGroup]);
        }
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    NSArray *groups = [acct groupArray];
    LJGroup *rowGroup = groups[rowIndex];
	
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
        [XJPreferences setShouldCheck: [anObject boolValue] forGroup: rowGroup];
    }
    [aTableView reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"check"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    LJAccount *acct = [[XJAccountManager defaultManager] defaultAccount];
    
    if([[aTableColumn identifier] isEqualToString: @"check"]) {
		id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
		BOOL shouldCheck = [[values valueForKey: XJCheckFriendsShouldCheck] boolValue];
		int checkGroupType = [[values valueForKey: CHECKFRIENDS_GROUP_TYPE] intValue];
		
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
// Grab title from popup menu and set defaults accordingly
- (IBAction)changeUpdateFrequency:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch ([sender tag]) {
        case 1: //Never
            [defaults setInteger:0 forKey:SUScheduledCheckIntervalKey];
            [defaults setBool:NO forKey:SUEnableAutomaticChecksKey];
            [updater setUpdateCheckInterval:0];
            break;
            
        case 2: //Daily
            [defaults setInteger:(24*60*60) forKey:SUScheduledCheckIntervalKey];
            [defaults setBool:YES forKey:SUEnableAutomaticChecksKey];
            [updater setUpdateCheckInterval:24*60*60];
            break;
            
        case 3: //Weekly
            [defaults setInteger:(7*24*60*60) forKey:SUScheduledCheckIntervalKey];
            [defaults setBool:YES forKey:SUEnableAutomaticChecksKey];
            [updater setUpdateCheckInterval:7*24*60*60];
            break;
            
        case 4: //Monthly
            [defaults setInteger:(4*7*24*60*60) forKey:SUScheduledCheckIntervalKey];
            [defaults setBool:YES forKey:SUEnableAutomaticChecksKey];
            [updater setUpdateCheckInterval:4*7*24*60*60];
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark Key-Value Observing
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context 
{
	if([keyPath isEqualToString: @"values." XJCheckFriendsShouldCheck]) {
		NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] integerValue];
		if(changeKind == NSKeyValueChangeSetting) {
			
			// Here, we *should* inspect [change objectForKey: NSKeyValueChangeNewKey]
			// But there's a bug in Tiger such that this is always nil.
			// Instead, we'll interrogate the defaults directly.
			// rdar://3777034 apparently.
			
			if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey: XJCheckFriendsShouldCheck] boolValue])
				[[XJCheckFriendsSessionManager sharedManager] startCheckingFriends];
			else
				[[XJCheckFriendsSessionManager sharedManager] stopCheckingFriends];
		}
	}
	
	if([keyPath isEqualToString: @"values."CHECKFRIENDS_GROUP_TYPE]) {
		[checkFriendsGroupTable reloadData];
	}
}

@end
