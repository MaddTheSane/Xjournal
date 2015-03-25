/* AccountEditWindowController */

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>

@interface XJAccountEditWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSPanel *newAccountSheet;
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSTableView *table;
    IBOutlet NSTextField *usernameField;

    IBOutlet NSButton *deleteButton;

    BOOL isEditingAccount;
    LJAccount *editedAccount;
}
- (IBAction)addAccount:(id)sender;
- (IBAction)removeAccount:(id)sender;
- (IBAction)editAccount: (id)sender;

- (IBAction)commitSheet: (id)sender;
- (IBAction)cancelSheet: (id)sender;

- (IBAction)openJournalCreatePage: (id)sender;
@end
