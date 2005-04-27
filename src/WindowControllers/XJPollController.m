#import "XJPollController.h"
#import "LJPollMultipleOptionQuestion.h"
#import "LJPollScaleQuestion.h"
#import "LJPollTextEntryQuestion.h"

@implementation XJPollController
- (id)init
{
    if(self == [super initWithWindowNibName: @"Poll2"]) {
		LJPoll *newPoll = [[[LJPoll alloc] init] autorelease];
		[newPoll setViewingPermissions: LJPollAllView];
		[newPoll setVotingPermissions: LJPollAllVote];
        [self setPoll: newPoll];
    }
    return self;
}

- (void)windowDidLoad {
	currentView = editMasterView;	
}

- (IBAction)addQuestion: (id)sender {
	NSBeginAlertSheet(@"Add Question",
					  @"Multiple Choice",
					  @"Scale",
					  @"Text",
					  [self window],
					  self,
					  @selector(sheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"Which kind of question would you like to add?");
}

- (void)sheetDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (id)context {
	
	if(returnCode == NSAlertDefaultReturn) {
		// Install multiple choice
		LJPollQuestion *q = [LJPollMultipleOptionQuestion questionOfType: LJPollRadioType];
		[poll insertObject: q inQuestionsAtIndex: [poll countOfQuestions]];
	}
	else if(returnCode == NSAlertAlternateReturn) {
		// Install Scale
		LJPollQuestion *q = [LJPollScaleQuestion scaleQuestionWithStartValue: 0 end: 100 step: 10];
		[poll insertObject: q inQuestionsAtIndex: [poll countOfQuestions]];
	}
	else if(returnCode == NSAlertOtherReturn) {
		// Install text
		LJPollQuestion *q = [LJPollTextEntryQuestion textEntryQuestionWithSize: 50 maxLength: 100];
		[poll insertObject: q inQuestionsAtIndex: [poll countOfQuestions]];
	}
}


 - (void)tableViewSelectionDidChange: (NSNotification *)note {
	NSLog(@"tableviewselectiondidchange starts");
	if([[questionController selectedObjects] count] > 0) {
		id selectedQuestion = [[questionController selectedObjects] objectAtIndex: 0];
		
		[currentView removeFromSuperview];
		[self unbindView: currentView];
		
		if([selectedQuestion isKindOfClass: [LJPollTextEntryQuestion class]]) {
			NSLog(@"Selected text q");
			[splitView addSubview: textEditView];
			[self bindTextView];
			currentView = textEditView;
		}
		else if([selectedQuestion isKindOfClass: [LJPollScaleQuestion class]]) {
			NSLog(@"Selected scale q");
			[splitView addSubview: scaleEditView];
			[self bindScaleView];
			currentView = scaleEditView;
		}
		else {
			NSLog(@"Selected MC q");
			[splitView addSubview: multipleEditView];
			[self bindMultipleChoiceView];
			currentView = multipleEditView;	
		}
	}
	NSLog(@"tableviewselectiondidchange returns");
}

- (void)bindScaleView {
	
	[scaleQuestionTextField bind: @"value"
						toObject: questionController
					 withKeyPath: @"selection.question"
						 options: nil];

	[scaleStartTextField bind: @"value"
					 toObject: questionController
				  withKeyPath: @"selection.startValue"
					  options: nil];
	
	[scaleEndTextField bind: @"value"
					 toObject: questionController
				  withKeyPath: @"selection.end"
					  options: nil];

	[scaleStepTextField bind: @"value"
					 toObject: questionController
				  withKeyPath: @"selection.step"
					  options: nil];
	NSLog(@"bindScaleView returns");
}

- (void)bindTextView {
	[textQuestionTextField bind: @"value"
					   toObject: questionController
					withKeyPath: @"selection.question"
						options: nil];
	
	[textSizeTextField bind: @"value"
				   toObject: questionController
				withKeyPath: @"selection.size"
					options: nil];
	
	[textMaxLengthTextField bind: @"value"
						toObject: questionController
					 withKeyPath: @"selection.maxLength"
						 options: nil];
}

-(void)bindMultipleChoiceView {
	[multipleQuestionField bind: @"value"
					   toObject: questionController
					withKeyPath: @"selection.question"
						options: nil];
	
	[multipleAnswerController bind: @"contentArray"
						  toObject: questionController
					   withKeyPath: @"selection.answers"
						   options: nil];
	
	[multipleAnswerColumn bind: @"value"
					  toObject: multipleAnswerController
				   withKeyPath: @"arrangedObjects.textValue"
					   options: nil];
	
	[multipleTypePopup bind: @"selectedTag"
				   toObject: questionController
				withKeyPath: @"selection.type"
					options: nil];
}

- (void)unbindView: (NSView *)view {
	if([view isEqualTo: scaleEditView]) {
		[scaleQuestionTextField unbind: @"value"];
		[scaleStartTextField unbind: @"value"];
		[scaleEndTextField unbind: @"value"];
		[scaleStepTextField unbind: @"value"];
	}
	else if([view isEqualTo: textEditView]) {
		[textQuestionTextField unbind: @"value"];	
		[textSizeTextField unbind: @"value"];
		[textMaxLengthTextField unbind: @"value"];
	}
	else if([view isEqualTo: multipleEditView]) {
		[multipleQuestionField unbind: @"value"];
		[multipleAnswerController unbind: @"contentArray"];
		[multipleAnswerColumn unbind: @"value"];
		[multipleTypePopup bind: @"selectedTag"];
	}
}

// =========================================================== 
// - poll:
// =========================================================== 
- (LJPoll *)poll {
    return poll; 
}

// =========================================================== 
// - setPoll:
// =========================================================== 
- (void)setPoll:(LJPoll *)aPoll {
    if (poll != aPoll) {
        [aPoll retain];
        [poll release];
		
        poll = aPoll;
   }
}
@end
