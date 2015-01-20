/* XJPreferencesController */

#import <Cocoa/Cocoa.h>

@class SUUpdater;

@interface XJPreferencesController : NSWindowController
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
- (void)changeTextFont:(id)sender;
- (void)changeFont:(id)sender;
- (IBAction)openAccountWindow: (id)sender;
- (void)buildSoundMenu;
- (IBAction)setSelectedFriendsSound:(id)sender;
- (IBAction)changeUpdateFrequency:(id)sender;

@end
