/* XJPollEditorController */

#import <Cocoa/Cocoa.h>
#import "LJPoll.h"
#import "LJPollQuestion.h"

@interface XJPollEditorController : NSWindowController
{
    LJPoll *thePoll;
    LJPollQuestion *currentlyEditedQuestion;
    NSWindow *currentSheet;

    NSMutableDictionary *toolbarItemCache;
    id currentlyEditedQuestionMemento;
    
    IBOutlet NSTextField *pollName;
    IBOutlet NSTableView *questionTable;
    IBOutlet NSPopUpButton *resultAccess;

    IBOutlet NSDrawer *drawer;
    IBOutlet NSTextView *drawerTextView;
    
    IBOutlet NSTableView *multipleAnswerTable;
    IBOutlet NSTextField *multipleQuestion;
    IBOutlet NSPanel *multipleSheet;
    IBOutlet NSPopUpButton *multipleType;

    IBOutlet NSPanel *scaleSheet;
    IBOutlet NSTextField *scaleQuestionField, *scaleStartField, *scaleEndField, *scaleStepField;

    IBOutlet NSTextField *textQuestionField, *textSizeField, *textMaxLengthField;
    IBOutlet NSPanel *textSheet;
    IBOutlet NSPopUpButton *votingAccess;
}

- (IBAction)editSelectedQuestion: (id)sender;
- (IBAction)deleteSelectedQuestion:(id)sender;

- (IBAction)moveSelectedQuestionUp: (id)sender;
- (IBAction)moveSelectedQuestionDown: (id)sender;

- (IBAction)setVotingAccess: (id)sender;
- (IBAction)setResultAccess: (id)sender;
- (IBAction)setPollName: (id)sender;

- (IBAction)addMultipleAnswer:(id)sender;
- (IBAction)addMultipleQuestion:(id)sender;
- (IBAction)deleteMultipleAnswer:(id)sender;
- (IBAction)setMultipleOptionType: (id)sender;

- (IBAction)addScaleQuestion:(id)sender;

- (IBAction)addTextQuestion:(id)sender;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)commitSheet:(id)sender;
@end
