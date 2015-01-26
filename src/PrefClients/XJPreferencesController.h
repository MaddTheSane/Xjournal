/* XJPreferencesController */

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

@interface XJPreferencesController : NSWindowController <NSToolbarDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
	NSMutableDictionary *items;
	
	IBOutlet NSView *accountsView;
	IBOutlet NSView *musicView;
	IBOutlet NSView *friendsView;
	IBOutlet NSView *historyView;
	IBOutlet NSView *weblogsView;
	IBOutlet NSView *softwareUpdateView;
	
	IBOutlet NSTableView *checkFriendsGroupTable;
	IBOutlet NSPopUpButton *soundSelection;
	IBOutlet NSPopUpButton *updateCheckSelection;
	
	IBOutlet SUUpdater *updater;
}

- (void)switchViews:(NSToolbarItem *)item;
- (IBAction)changeTextFont:(id)sender;
- (IBAction)changeFont:(id)sender;
- (IBAction)openAccountWindow: (id)sender;
- (void)buildSoundMenu;
- (IBAction)setSelectedFriendsSound:(id)sender;
- (IBAction)changeUpdateFrequency:(id)sender;

@end
