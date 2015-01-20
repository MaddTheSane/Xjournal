/* AccountEditWindowController */

#import <Cocoa/Cocoa.h>
#import <LJKit/LJKit.h>

@interface XJAccountEditWindowController : NSWindowController
{
    IBOutlet id newAccountSheet;
    IBOutlet id passwordField;
    IBOutlet id table;
    IBOutlet id usernameField;

    IBOutlet id deleteButton;

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
