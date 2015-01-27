/* XJPreferencesController */

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

@interface XJPreferencesController : NSWindowController <NSToolbarDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
	NSMutableDictionary *items;
	
	
	IBOutlet NSTableView *checkFriendsGroupTable;
	IBOutlet NSPopUpButton *soundSelection;
	IBOutlet NSPopUpButton *updateCheckSelection;
	
	IBOutlet SUUpdater *updater;
}
@property (weak) IBOutlet NSView *accountsView;
@property (weak) IBOutlet NSView *musicView;
@property (weak) IBOutlet NSView *friendsView;
@property (weak) IBOutlet NSView *historyView;
@property (weak) IBOutlet NSView *weblogsView;
@property (weak) IBOutlet NSView *softwareUpdateView;
@property (weak) IBOutlet NSView *notificationsView;

- (void)switchViews:(NSToolbarItem *)item;
- (IBAction)changeTextFont:(id)sender;
- (IBAction)changeFont:(id)sender;
- (IBAction)openAccountWindow: (id)sender;
- (void)buildSoundMenu;
- (IBAction)setSelectedFriendsSound:(id)sender;
- (IBAction)changeUpdateFrequency:(id)sender;

@end
