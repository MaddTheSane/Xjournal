#import "XJAccountEditWindowController.h"
#import "XJAccountManager.h"
#import "XJPreferences.h"

@implementation XJAccountEditWindowController

- (instancetype)init
{
    if(self = [super initWithWindowNibName:@"AccountEditWindow"]) {
        
    }
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
    
    [self.window beginSheet:newAccountSheet completionHandler:^(NSModalResponse returnCode) {
        // Do nothing
    }];
}

- (IBAction)removeAccount:(id)sender
{
    if([[XJAccountManager defaultManager] numberOfAccounts] > 1) {
        NSInteger selectedAccountIndex = [table selectedRow];

        if (selectedAccountIndex != -1) {
            NSArray *usernames = [[[[XJAccountManager defaultManager] accounts] allKeys] sortedArrayUsingSelector: @selector(compare:)];
            NSString *username = [usernames[selectedAccountIndex] copy];

            [[XJAccountManager defaultManager] removeAccountWithUsername: username];

            [table reloadData];
        }
    }
    else {
        NSAlert *alert = [NSAlert new];
        alert.messageText = NSLocalizedString(@"Cannot Delete last account", @"");
        alert.informativeText = NSLocalizedString(@"You must always have one account defined.  To delete this account, make another one first, then delete this one", @"");
        alert.alertStyle = NSAlertStyleCritical;
        [alert beginSheetModalForWindow: self.window completionHandler:^(NSModalResponse returnCode) {
            //Do nothing
        }];
    }
}

- (IBAction)editAccount: (id)sender
{
    NSInteger row = [table selectedRow];
    if(row == -1) return;
    
    XJAccountManager *man = [XJAccountManager defaultManager];
    NSDictionary *accts = [man accounts];
    NSArray *usernames = [[accts allKeys] sortedArrayUsingSelector: @selector(compare:)];

    editedAccount = [man accountForUsername: usernames[row]];

    [usernameField setStringValue: [editedAccount username]];
    [usernameField setEnabled: NO];
    [passwordField setStringValue: [man passwordForUsername: [editedAccount username]]];

    isEditingAccount = YES;
    
    [self.window beginSheet: newAccountSheet completionHandler:^(NSModalResponse returnCode) {
        // Do nothing
    }];
}

- (IBAction)commitSheet: (id)sender
{
    [self.window endSheet: newAccountSheet];
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
    [self.window endSheet: newAccountSheet];
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	NSInteger i = [[[[XJAccountManager defaultManager] accounts] allKeys] count];
	return i;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    XJAccountManager *man = [XJAccountManager defaultManager];
    NSDictionary *accts = [man accounts];
    NSArray *usernames = [[accts allKeys] sortedArrayUsingSelector: @selector(compare:)];
	
    if([[aTableColumn identifier] isEqualToString: @"default"]) {
		LJAccount *defaultAccount = [man defaultAccount];
        if([usernames[rowIndex] isEqualToString: [defaultAccount username]]) {
            return @1;
		}
        else {
            return @0;
		}
    } else {
        return [NSString stringWithFormat:@"%@", usernames[rowIndex]];
    }
	NSAssert(NO, @"Should never get here");
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *usernames = [[[[XJAccountManager defaultManager] accounts] allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSString *username = usernames[rowIndex];
    [[XJAccountManager defaultManager] setDefaultUsername: username];
    [table reloadData];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[aTableColumn identifier] isEqualToString: @"default"];
}

@end
