/* XJScriptWindowController */

#import <Cocoa/Cocoa.h>

@interface XJScriptWindowController : NSWindowController
{
	NSMutableArray *scripts;
	IBOutlet NSArrayController *tableArrayController;
	IBOutlet NSTableView *table;
	
	IBOutlet NSMenu *contextualMenu;
	IBOutlet NSPopUpButton *actionButton;
}
- (IBAction)runSelectedScript: (id)sender;

- (NSMutableArray *)scripts;
- (void)setScripts:(NSMutableArray *)aScripts;

- (NSString *)directory;

@end
