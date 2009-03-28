#import "XJAccountEditWindowController.h"
#import "XJAccountManager.h"
#import "XJPreferences.h"

@implementation XJAccountEditWindowController

- (id)init
{
    if([super initWithWindowNibName:@"AccountEditWindow"] == nil)
        return nil;
    return self;
}

- (void)windowDidLoad
{
    // Set up the account table
    NSButtonCell *tPrototypeCell = [[NSButtonCell alloc] initTextCell: @""];

    [tPrototypeCell setEditable: NO];
    [tPrototypeCell setButtonType:NSSwitchButton];
    [tPrototypeCell setImagePosition:NSImageOnly];
    [tPrototypeCell setControlSize:NSSmallControlSize];

    [[table tableColumnWithIdentifier: @"default"] setDataCell: tPrototypeCell];
    [tPrototypeCell release];

    [table setTarget: self];
    [table setDoubleAction: @selector(editAccount:)];

    isEditingAccount = NO;
    
    [table reloadData];
}

- (IBAction)addAccount:(id)sender
{
    [usernameField setStringValue: @""];
	[usernameField setEnabled:YES];
    [passwordField setStringValue: @""];
    
    [NSApp beginSheet: newAccountSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (IBAction)removeAccount:(id)sender
{
    if([[XJAccountManager defaultManager] numberOfAccounts] > 1) {
        int selectedAccountIndex = [table selectedRow];

        if(selectedAccountIndex != -1) {
            NSArray *usernames = [[[[XJAccountManager defaultManager] accounts] allKeys] sortedArrayUsingSelector: @selector(compare:)];
            NSString *username = [[usernames objectAtIndex: selectedAccountIndex] copy];
            [usernames release];

            [[XJAccountManager defaultManager] removeAccountWithUsername: username];
            [username release];

            [table reloadData];
        }
    }
    else {
        NSBeginCriticalAlertSheet(NSLocalizedString(@"Cannot Delete last account", @""),
                                  @"OK",
                                  nil,
                                  nil,
                                  [self window],
                                  nil,
                                  nil,
                                  nil,
                                  nil,
                                  NSLocalizedString(@"You must always have one account defined.  To delete this account, make another one first, then delete this one", @""));
    }
}

- (IBAction)editAccount: (id)sender
{
    int row = [table selectedRow];
    if(row == -1) return;
    
    XJAccountManager *man = [XJAccountManager defaultManager];
    NSDictionary *accts = [man accounts];
    NSArray *usernames = [[accts allKeys] sortedArrayUsingSelector: @selector(compare:)];

    editedAccount = [man accountForUsername: [usernames objectAtIndex: row]];

    [usernameField setStringValue: [editedAccount username]];
    [usernameField setEnabled: NO];
    [passwordField setStringValue: [man passwordForUsername: [editedAccount username]]];

    isEditingAccount = YES;
    
    [NSApp beginSheet: newAccountSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (IBAction)commitSheet: (id)sender
{
    [NSApp endSheet: newAccountSheet];
    [newAccountSheet orderOut: nil];

    if(!isEditingAccount) {
        BOOL isFirstAccount = [[XJAccountManager defaultManager] numberOfAccounts] == 0;

        [[XJAccountManager defaultManager] addAccountWithUsername: [usernameField stringValue] password: [passwordField stringValue]];
		
        if(isFirstAccount) {
            [[XJAccountManager defaultManager] setDefaultUsername: [usernameField stringValue]];

            [[NSNotificationCenter defaultCenter] postNotificationName: XJFirstAccountInstalled object:self];
        }
    }
    else {
        [[XJAccountManager defaultManager] setPassword: [passwordField stringValue] forUsername: [editedAccount username]];
		isEditingAccount = NO;
    }
	editedAccount = nil;
    [table reloadData];
}

- (IBAction)cancelSheet: (id)sender
{
    [NSApp endSheet: newAccountSheet];
    [newAccountSheet orderOut: nil];
	isEditingAccount = NO;
	editedAccount = nil;
}

- (IBAction)openJournalCreatePage: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.livejournal.com/create.bml"]];
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	int i = [[[[XJAccountManager defaultManager] accounts] allKeys] count];
    //return [[[[XJAccountManager defaultManager] accounts] allKeys] count];
	return i;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    XJAccountManager *man = [XJAccountManager defaultManager];
    NSDictionary *accts = [man accounts];
    NSArray *usernames = [[accts allKeys] sortedArrayUsingSelector: @selector(compare:)];
	
    if([[aTableColumn identifier] isEqualToString: @"default"]) {
		LJAccount *defaultAccount = [man defaultAccount];
        if([[usernames objectAtIndex: rowIndex] isEqualToString: [defaultAccount username]]) {
            return [NSNumber numberWithInt: 1];
		}
        else {
            return [NSNumber numberWithInt: 0];
		}
    } else {
        return [NSString stringWithFormat:@"%@", [usernames objectAtIndex: rowIndex]];
    }
	NSAssert(NO, @"Should never get here");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSArray *usernames = [[[[XJAccountManager defaultManager] accounts] allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSString *username = [usernames objectAtIndex: rowIndex];
    [[XJAccountManager defaultManager] setDefaultUsername: username];
    [table reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"default"];
}
@end
