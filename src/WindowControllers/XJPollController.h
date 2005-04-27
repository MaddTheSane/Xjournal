/* XJPollController */

#import <Cocoa/Cocoa.h>
#import "LJPoll.h"
#import "LJPollQuestion.h"

@interface XJPollController : NSWindowController
{
    IBOutlet id editMasterView;
    IBOutlet id multipleEditView;
    
	IBOutlet id scaleEditView;
	IBOutlet NSTextField *scaleQuestionTextField;
	IBOutlet NSTextField *scaleStartTextField;
	IBOutlet NSTextField *scaleEndTextField;
	IBOutlet NSTextField *scaleStepTextField;
	
    IBOutlet id textEditView;
	IBOutlet NSTextField *textQuestionTextField;
	IBOutlet NSTextField *textSizeTextField;
	IBOutlet NSTextField *textMaxLengthTextField;
	
	IBOutlet NSTextField *multipleQuestionField;
	IBOutlet NSTableColumn *multipleAnswerColumn;
	IBOutlet NSPopUpButton *multipleTypePopup;
	IBOutlet NSArrayController *multipleAnswerController;
	
	IBOutlet NSSplitView *splitView;
	
	NSView *currentView;
	
	IBOutlet NSArrayController *questionController;
	
	LJPoll *poll;
}

- (IBAction)addQuestion: (id)sender;

- (void)bindScaleView;
- (void)bindTextView;
-(void)bindMultipleChoiceView;

- (void)unbindView: (NSView *)view;

- (LJPoll *)poll;
- (void)setPoll:(LJPoll *)aPoll;
@end
