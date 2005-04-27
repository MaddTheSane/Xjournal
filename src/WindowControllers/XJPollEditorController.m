#import "XJPollEditorController.h"

#import "LJPollMultipleOptionQuestion.h"
#import "LJPollQuestion.h"
#import "LJPollTextEntryQuestion.h"
#import "LJPollScaleQuestion.h"
#import "XJPollTypeVT.h"

#define kMultipleAnswerPasteboardType @"kMultipleAnswerPasteboardType"
#define kPollQuestionPasteboardType @"kPollQuestionPasteboardType"
#define kPollAddTextItemIdentifier @"kPollAddTextItemIdentifier"
#define kPollAddMultipleItemIdentifier @"kPollAddMultipleItemIdentifier"
#define kPollAddScaleItemIdentifier @"kPollAddScaleItemIdentifier"

#define kPollDeleteItemIdentifier @"kPollDeleteItemIdentifier"
#define kPollMoveUpItemIdentifier @"kPollMoveUpItemIdentifier"
#define kPollMoveDownItemIdentifier @"kPollMoveDownItemIdentifier"
#define kPollShowCodeItemIdentifier @"kPollShowCodeItemIdentifier"

@interface XJPollEditorController (PrivateAPI)
- (void)updateDrawer;
- (void)runSheet: (NSWindow *)sheet;
- (void)startObservingPoll: (LJPoll *)thePoll;
- (void)stopObservingPoll: (LJPoll *)thePoll;
@end

@implementation XJPollEditorController

+(void)initialize {
	[NSValueTransformer setValueTransformer: [[[XJPollTypeVT alloc] init] autorelease]
									forName: @"XJPollTypeVT"];
}

- (id)init
{
    if(self == [super initWithWindowNibName: @"PollEditor"]) {
		LJPoll *newPoll = [[[LJPoll alloc] init] autorelease];
		[newPoll setViewingPermissions: LJPollAllView];
		[newPoll setVotingPermissions: LJPollAllVote];
        [self setPoll: newPoll];
		
    }
    return self;
}

- (void)windowDidLoad
{
    [questionTable setTarget: self];
    [questionTable setDoubleAction: @selector(editSelectedQuestion:)];

    // Set the height of the drawer
    NSSize currentDrawerSize = [drawer contentSize];
    [drawer setContentSize: NSMakeSize(currentDrawerSize.width, 150)];
    
    [drawer open];
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
        [self stopObservingPoll: poll];
		
		[aPoll retain];
        [poll release];
		poll = aPoll;
		
		[self startObservingPoll: poll];
    }
}

- (IBAction)editSelectedQuestion: (id)sender
{
    int selectedRow = [questionTable selectedRow];
    if(selectedRow != -1) {
        [self setCurrentlyEditedQuestion: [poll objectInQuestionsAtIndex: selectedRow]];
        currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
        
        if([currentlyEditedQuestion isKindOfClass: [LJPollMultipleOptionQuestion class]])
            [self runSheet: multipleSheet];

        else if([currentlyEditedQuestion isKindOfClass: [LJPollScaleQuestion class]])
            [self runSheet: scaleSheet];

        else if([currentlyEditedQuestion isKindOfClass: [LJPollTextEntryQuestion class]])
            [self runSheet: textSheet];
    }
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
		[self addMultipleQuestion: self];
	}
	else if(returnCode == NSAlertAlternateReturn) {
		// Install Scale
		[self addScaleQuestion: self];
	}
	else if(returnCode == NSAlertOtherReturn) {
		// Install text
		[self addTextQuestion: self];
	}
}

- (IBAction)addMultipleQuestion:(id)sender
{
    [self setCurrentlyEditedQuestion: [LJPollMultipleOptionQuestion questionOfType: LJPollRadioType]];
    currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];

	[poll insertObject: currentlyEditedQuestion inQuestionsAtIndex: [poll countOfQuestions]];

    [self performSelector: @selector(runSheet:)
			   withObject: multipleSheet
			   afterDelay: 0.5];
    [self updateDrawer];
}

- (IBAction)addMultipleAnswer:(id)sender {
	NSMutableDictionary *answer = [NSMutableDictionary dictionary];
	[answer setObject: @"answer" forKey: @"answerText"];
	
	[[[self currentlyEditedQuestion] mutableArrayValueForKey: @"answers"] addObject: answer];
	
	int idx = [[[self currentlyEditedQuestion] answers] count] - 1;
	[multipleAnswerTable selectRow: idx byExtendingSelection: NO];
	
	[multipleAnswerTable editColumn: 0
								row: idx
						  withEvent: nil
							 select: YES];
}

- (IBAction)addScaleQuestion:(id)sender
{
    [self setCurrentlyEditedQuestion: [LJPollScaleQuestion scaleQuestionWithStartValue: 1 end: 10 step: 1]];
    currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
        
	[poll insertObject: currentlyEditedQuestion inQuestionsAtIndex: [poll countOfQuestions]];

	[self performSelector: @selector(runSheet:)
			   withObject: scaleSheet
			   afterDelay: 0.5];
    [self updateDrawer];
}

- (IBAction)addTextQuestion:(id)sender
{
    [self setCurrentlyEditedQuestion: [LJPollTextEntryQuestion textEntryQuestionWithSize: 30 maxLength: 15]];
    currentlyEditedQuestionMemento = [[currentlyEditedQuestion memento] retain];
    
	[poll insertObject: currentlyEditedQuestion inQuestionsAtIndex: [poll countOfQuestions]];
	
	[self performSelector: @selector(runSheet:)
			   withObject: textSheet
			   afterDelay: 0.5];
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
        
    [self updateDrawer];

    [NSApp endSheet: currentSheet];
    [currentSheet orderOut: nil];
    currentSheet = nil;
}


// =========================================================== 
// - currentlyEditedQuestion:
// =========================================================== 
- (LJPollQuestion *)currentlyEditedQuestion {
    return currentlyEditedQuestion; 
}

// =========================================================== 
// - setCurrentlyEditedQuestion:
// =========================================================== 
- (void)setCurrentlyEditedQuestion:(LJPollQuestion *)aCurrentlyEditedQuestion {
        currentlyEditedQuestion = aCurrentlyEditedQuestion;
}


// =========================================================== 
// - currentSheet:
// =========================================================== 
- (NSWindow *)currentSheet {
    return currentSheet; 
}

// =========================================================== 
// - setCurrentSheet:
// =========================================================== 
- (void)setCurrentSheet:(NSWindow *)aCurrentSheet {
	currentSheet = aCurrentSheet;
}
@end

@implementation XJPollEditorController (PrivateAPI)
- (void)runSheet: (NSWindow *)sheet {
	[self setCurrentSheet: sheet];
	
	if([[self currentSheet] isEqualTo: multipleSheet]) {
		[multipleAnswersArrayController bind: @"contentArray"
									toObject: [self currentlyEditedQuestion]
								 withKeyPath: @"answers"
									 options: nil];
		
		[multipleType bind: @"selectedTag"
				  toObject: [self currentlyEditedQuestion]
			   withKeyPath: @"type"
				   options: nil];
	}
	else {
		[multipleAnswersArrayController unbind: @"contentArray"];
		[multipleType unbind: @"selectedTag"];
	}
	
    [NSApp beginSheet: [self currentSheet]
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
}

- (void)updateDrawer
{
    [drawerTextView setString: [poll htmlRepresentation]];
}

- (void)startObservingPoll: (LJPoll *)thePoll {
	[thePoll addObserver: self
			  forKeyPath: @"questions"
				 options: NSKeyValueObservingOptionOld
				 context: nil];
	
	[thePoll addObserver: self
			  forKeyPath: @"name"
				 options: NSKeyValueObservingOptionOld
				 context: nil];
	
	[thePoll addObserver: self
			  forKeyPath: @"votingPermissions"
				 options: NSKeyValueObservingOptionOld
				 context: nil];
	
	[thePoll addObserver: self
			  forKeyPath: @"viewingPermissions"
				 options: NSKeyValueObservingOptionOld
				 context: nil];
}

- (void)stopObservingPoll: (LJPoll *)thePoll {
	[thePoll removeObserver: self
				 forKeyPath: @"questions"];
	
	[thePoll removeObserver: self
				 forKeyPath: @"name"];
	
	[thePoll removeObserver: self
				 forKeyPath: @"votingPermissions"];
	
	[thePoll removeObserver: self
				 forKeyPath: @"viewingPermissions"];
}

- (void)observeValueForKeyPath: (NSString *)keyPath
					  ofObject: (id)object
						change: (NSDictionary *)change
					   context: (void *)context
{
	[self updateDrawer];
}

@end