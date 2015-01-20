#import "XJPollEditorController.h"

#import "LJPollMultipleOptionQuestion.h"
#import "LJPollQuestion.h"
#import "LJPollTextEntryQuestion.h"
#import "LJPollScaleQuestion.h"
#import <OgreKit/OgreKit.h>

#define kMultipleAnswerPasteboardType @"kMultipleAnswerPasteboardType"
#define kPollQuestionPasteboardType @"kPollQuestionPasteboardType"

@interface XJPollEditorController (PrivateAPI)
- (void)runMultipleSheet;
- (void)runScaleSheet;
- (void)runTextSheet;
- (void)updateDrawer;
@end

@implementation XJPollEditorController

- (id)init
{
    if(self == [super initWithWindowNibName: @"PollEditor"]) {
        thePoll = [[LJPoll alloc] init];
    }
    return self;
}

- (void)windowDidLoad
{
    NSToolbar *toolBar = [[NSToolbar alloc] initWithIdentifier: @"kPollToolbar"];
    [toolBar setAllowsUserCustomization: YES];
    [toolBar setAutosavesConfiguration: YES];
    [toolBar setDelegate: self];
    [[self window] setToolbar: toolBar];
    [toolBar release];
    
    [pollName setStringValue: [thePoll name]];
    [questionTable setTarget: self];
    [questionTable setDoubleAction: @selector(editSelectedQuestion:)];

    // Set the height of the drawer
    NSSize currentDrawerSize = [drawer contentSize];
    [drawer setContentSize: NSMakeSize(currentDrawerSize.width, 150)];
    
    [drawer open];
}

- (IBAction)setPollName: (id)sender
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"\""];
    [thePoll setName: [regex replaceAllMatchesInString: [sender stringValue] withString: @"&quot;"]];
    [self updateDrawer];
}

- (IBAction)setVotingAccess: (id)sender
{
    [thePoll setVotingPermissions: [[sender selectedItem] tag]];
    [self updateDrawer];
}

- (IBAction)setResultAccess: (id)sender
{
    [thePoll setViewingPermissions: [[sender selectedItem] tag]];
    [self updateDrawer];
}

- (IBAction)editSelectedQuestion: (id)sender
{
    int selectedRow = [questionTable selectedRow];
    if(selectedRow != -1) {
        currentlyEditedQuestion = [thePoll questionAtIndex: selectedRow];
        currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
        
        if([currentlyEditedQuestion isKindOfClass: [LJPollMultipleOptionQuestion class]])
            [self runMultipleSheet];

        else if([currentlyEditedQuestion isKindOfClass: [LJPollScaleQuestion class]])
            [self runScaleSheet];

        else if([currentlyEditedQuestion isKindOfClass: [LJPollTextEntryQuestion class]])
            [self runTextSheet];
    }
}

- (IBAction)moveSelectedQuestionUp: (id)sender
{
	[currentSheet endEditingFor: nil];
    if([sender tag] == 0) {
        if([questionTable numberOfSelectedRows] == 1) {
            [thePoll moveQuestionAtIndex: [questionTable selectedRow] toIndex: [questionTable selectedRow] - 1];
            [questionTable selectRow: [questionTable selectedRow] - 1 byExtendingSelection: NO];
        }
        [questionTable reloadData];
    }

    if([sender tag] == 1) { // answer table
        if([multipleAnswerTable numberOfSelectedRows] == 1) {
            [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion moveAnswerAtIndex: [multipleAnswerTable selectedRow] toIndex: [multipleAnswerTable selectedRow]-1];
            [multipleAnswerTable selectRow: [multipleAnswerTable selectedRow] - 1 byExtendingSelection: NO];
            [multipleAnswerTable reloadData];
        }
    }

    [self updateDrawer];
}

- (IBAction)moveSelectedQuestionDown: (id)sender
{
	[currentSheet endEditingFor: nil];
    if([sender tag] == 0) {
        if([questionTable numberOfSelectedRows] == 1) {
            [thePoll moveQuestionAtIndex: [questionTable selectedRow] toIndex: [questionTable selectedRow] + 1];
            [questionTable selectRow: [questionTable selectedRow] + 1 byExtendingSelection: NO];
        }
        [questionTable reloadData];
    }

     if([sender tag] == 1) {
        if([multipleAnswerTable numberOfSelectedRows] == 1) {
            [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion moveAnswerAtIndex: [multipleAnswerTable selectedRow] toIndex: [multipleAnswerTable selectedRow] + 1];
            [multipleAnswerTable selectRow: [multipleAnswerTable selectedRow] + 1 byExtendingSelection: NO];
        }
        [multipleAnswerTable reloadData];
    }

    [self updateDrawer];
}

- (IBAction)addMultipleAnswer:(id)sender
{
    [multipleSheet endEditingFor: nil];
    [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion addAnswer: @"answer"];
    [multipleAnswerTable reloadData];
    [multipleAnswerTable selectRow: [multipleAnswerTable numberOfRows]-1 byExtendingSelection: NO];
    [multipleAnswerTable editColumn: 0
                                row: [multipleAnswerTable numberOfRows]-1
                          withEvent: nil
                             select: YES];
    [self updateDrawer];
}

- (IBAction)addMultipleQuestion:(id)sender
{
    currentlyEditedQuestion = [LJPollMultipleOptionQuestion questionOfType: LJPollRadioType];
    currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
        
    [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion addAnswer: @"answer"];
    
    [thePoll addQuestion: currentlyEditedQuestion];
    [questionTable reloadData];

    [self runMultipleSheet];
    [self updateDrawer];
}

- (IBAction)setMultipleOptionType: (id)sender
{
    [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion setType: [[sender selectedItem] tag]];
}

- (IBAction)addScaleQuestion:(id)sender
{
    currentlyEditedQuestion = [LJPollScaleQuestion scaleQuestionWithStart: 1 end: 10 step: 1];
    currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
        
    [thePoll addQuestion: currentlyEditedQuestion];
    [questionTable reloadData];
    [self runScaleSheet];
    [self updateDrawer];
}

- (IBAction)addTextQuestion:(id)sender
{
    currentlyEditedQuestion = [LJPollTextEntryQuestion textEntryQuestionWithSize: 30 maxLength: 15];
    currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
    
    [thePoll addQuestion: currentlyEditedQuestion];
    [questionTable reloadData];
    [self runTextSheet];
    [self updateDrawer];
}

- (IBAction)cancelSheet:(id)sender
{
    [currentlyEditedQuestion restoreFromMemento: currentlyEditedQuestionMemento];
    [currentlyEditedQuestionMemento release];
    currentlyEditedQuestionMemento = nil;
        
    [NSApp endSheet: currentSheet];
    [currentSheet orderOut: nil];
    currentSheet = nil;
}

- (IBAction)commitSheet:(id)sender
{
    [currentSheet endEditingFor:nil];
    if([currentSheet isEqualTo: multipleSheet]) {
        [currentlyEditedQuestion setQuestion: [multipleQuestion stringValue]];
    }
    else if([currentSheet isEqualTo: scaleSheet]) {
        [currentlyEditedQuestion setQuestion: [scaleQuestionField stringValue]];
        [(LJPollScaleQuestion *)currentlyEditedQuestion setStart: [[scaleStartField objectValue] intValue]];
        [(LJPollScaleQuestion *)currentlyEditedQuestion setEnd: [[scaleEndField objectValue] intValue]];
        [(LJPollScaleQuestion *)currentlyEditedQuestion setStep: [[scaleStepField objectValue] intValue]];
    }
    else if([currentSheet isEqualTo: textSheet]) {
        [currentlyEditedQuestion setQuestion: [textQuestionField stringValue]];
        [(LJPollTextEntryQuestion *)currentlyEditedQuestion setSize: [textSizeField intValue]];
        [(LJPollTextEntryQuestion *)currentlyEditedQuestion setMaxLength: [textMaxLengthField intValue]];
    }
    
    [questionTable reloadData];
    [self updateDrawer];

    [NSApp endSheet: currentSheet];
    [currentSheet orderOut: nil];
    currentSheet = nil;
}

- (IBAction)deleteMultipleAnswer:(id)sender
{
	[[self window] endEditingFor: nil];
	
    NSEnumerator *selectedRows = [multipleAnswerTable selectedRowEnumerator];
    NSNumber *rowNumber;

    while(rowNumber = [selectedRows nextObject]) {
        [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion deleteAnswerAtIndex: [rowNumber intValue]];
    }

    [multipleAnswerTable reloadData];
    [self updateDrawer];
}

- (IBAction)deleteSelectedQuestion:(id)sender
{
    NSEnumerator *selectedRows = [questionTable selectedRowEnumerator];
    NSNumber *rowNumber;

    while(rowNumber = [selectedRows nextObject]) {
        [thePoll deleteQuestionAtIndex: [rowNumber intValue]];
    }

    [questionTable reloadData];
    [self updateDrawer];
}

// ----------------------------------------------------------------------------------------
// NSTableDataSource
// ----------------------------------------------------------------------------------------

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if([aTableView isEqualTo: questionTable]) {
        return [thePoll numberOfQuestions];
    }
    else if([aTableView isEqualTo: multipleAnswerTable]) {
        return [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion numberOfAnswers];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([aTableView isEqualTo: questionTable]) {
        LJPollQuestion *theQuestion = [thePoll questionAtIndex: rowIndex];
        if([[aTableColumn identifier] isEqualToString: @"question"])
            return [theQuestion question];
        else {
            if([theQuestion isKindOfClass: [LJPollMultipleOptionQuestion class]]) {
                switch([(LJPollMultipleOptionQuestion *)theQuestion type]) {
                    case LJPollRadioType:
                        return NSLocalizedString(@"Radio Buttons", @"");
                    case LJPollCheckBoxType:
                        return NSLocalizedString(@"Check Boxes", @"");
                    case LJPollDropDownType:
                        return NSLocalizedString(@"Drop Down Menu", @"");
                }
            }
            else if([theQuestion isKindOfClass: [LJPollTextEntryQuestion class]]) {
                return NSLocalizedString(@"Text", @"");
            }
            else {
                return [NSString stringWithFormat: NSLocalizedString(@"Scale (%d-%d by %d)", @""),
                    [(LJPollScaleQuestion *)theQuestion start],
                    [(LJPollScaleQuestion *)theQuestion end],
                    [(LJPollScaleQuestion *)theQuestion step]];
            }
        }
    }

    else if([aTableView isEqualTo: multipleAnswerTable]) {
        return [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion answerAtIndex: rowIndex];
    }
    return @"";
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return [aTableView isEqualTo: multipleAnswerTable];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if([aTableView isEqualTo: multipleAnswerTable]) {
        [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion setAnswer: anObject atIndex: rowIndex];
    }
}
@end

@implementation XJPollEditorController (PrivateAPI)
- (void)runMultipleSheet
{
    currentSheet = multipleSheet;
    [multipleQuestion setStringValue: [currentlyEditedQuestion question]];
    [multipleAnswerTable reloadData];

    int questionType = [(LJPollMultipleOptionQuestion *)currentlyEditedQuestion type];
    NSMenu *theMenu = [multipleType menu];    

    switch(questionType) {
        case LJPollRadioType:
            [multipleType selectItem: [theMenu itemAtIndex:0]];
            break;
        case LJPollCheckBoxType:
            [multipleType selectItem: [theMenu itemAtIndex: 1]];
            break;
        case LJPollDropDownType:
            [multipleType selectItem: [theMenu itemAtIndex: 2]];
            break;
    }
    
    [NSApp beginSheet: multipleSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (void)runScaleSheet
{
    currentSheet = scaleSheet;

    [scaleQuestionField setStringValue: [currentlyEditedQuestion question]];
    [scaleStartField setObjectValue: [NSNumber numberWithInt: [(LJPollScaleQuestion *)currentlyEditedQuestion start]]];
    [scaleEndField setObjectValue: [NSNumber numberWithInt: [(LJPollScaleQuestion *)currentlyEditedQuestion end]]];
    [scaleStepField setObjectValue: [NSNumber numberWithInt: [(LJPollScaleQuestion *)currentlyEditedQuestion step]]];

    [NSApp beginSheet: scaleSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (void)runTextSheet
{
    currentSheet = textSheet;

    [textQuestionField setStringValue: [currentlyEditedQuestion question]];
    [textSizeField setObjectValue: [NSNumber numberWithInt: [(LJPollTextEntryQuestion *)currentlyEditedQuestion size]]];
    [textMaxLengthField setObjectValue: [NSNumber numberWithInt: [(LJPollTextEntryQuestion *)currentlyEditedQuestion maxLength]]];

    [NSApp beginSheet: textSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (void)updateDrawer
{
    [drawerTextView setString: [thePoll htmlRepresentation]];
}
@end