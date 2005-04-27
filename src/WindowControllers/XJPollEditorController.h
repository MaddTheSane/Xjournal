/* XJPollEditorController */

#import <Cocoa/Cocoa.h>
#import "LJPoll.h"
#import "LJPollQuestion.h"

@interface XJPollEditorController : NSWindowController
{
    LJPoll *poll;
    LJPollQuestion *currentlyEditedQuestion;
    NSWindow *currentSheet;

	IBOutlet NSArrayController *multipleAnswersArrayController;
	
    NSMutableDictionary *toolbarItemCache;
    id currentlyEditedQuestionMemento;
    
    IBOutlet NSTableView *questionTable;

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
}

- (LJPoll *)poll;
- (void)setPoll:(LJPoll *)aPoll;

- (IBAction)editSelectedQuestion: (id)sender;

- (IBAction)addQuestion: (id)sender;
- (IBAction)addScaleQuestion:(id)sender;
- (IBAction)addTextQuestion:(id)sender;
- (IBAction)addMultipleQuestion:(id)sender;

- (IBAction)addMultipleAnswer:(id)sender;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)commitSheet:(id)sender;

- (LJPollQuestion *)currentlyEditedQuestion;
- (void)setCurrentlyEditedQuestion:(LJPollQuestion *)aCurrentlyEditedQuestion;
- (NSWindow *)currentSheet;
- (void)setCurrentSheet:(NSWindow *)aCurrentSheet;
@end
