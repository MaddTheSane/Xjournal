//
//  LJPoll.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPoll.h"


@implementation LJPoll
@synthesize name;
@synthesize votingPermissions = whoVote;
@synthesize viewingPermissions = whoView;

- (instancetype)init
{
    if (self = [super init]) {
    
    questions = [[NSMutableArray alloc] initWithCapacity: 30];
    name = @"NewPoll";
    }
    return self;
}

- (NSInteger)numberOfQuestions { return [questions count]; }

- (void)addQuestion: (LJPollQuestion *)newQ
{
    [questions addObject: newQ];
}

- (LJPollQuestion *)questionAtIndex: (NSInteger)idx
{
    return questions[idx];
}

- (void)moveQuestionAtIndex: (NSInteger)idx toIndex: (NSInteger)newIdx
{
    if(newIdx == idx) return;
    if(newIdx < 0 || newIdx >= [questions count]) return;

    id obj = questions[idx];
    [questions removeObjectAtIndex: idx];
    [questions insertObject: obj atIndex: newIdx];
}

// Insert the question at the given index
- (void)insertQuestion: (LJPollQuestion *)question atIndex:(NSInteger)idx
{
    [questions insertObject: question atIndex: idx];
}
    
- (void)deleteQuestionAtIndex: (NSInteger)idx
{
    [questions removeObjectAtIndex: idx];
}

- (void)deleteQuestionsAtIndexes:(NSIndexSet*)idx
{
	[questions removeObjectsAtIndexes:idx];
}

- (NSString *)htmlRepresentation
{
    NSMutableString *buf = [[NSMutableString alloc] initWithCapacity: 100];

    [buf appendString: @"<lj-poll"];

    // Append name
    [buf appendString: @" name=\""];
    if(name)
        [buf appendString: name];
    [buf appendString: @"\""];

    // Append voting permission property
    [buf appendString: @" whovote=\""];
    switch(whoVote) {
        case LJPollAllVote:
            [buf appendString: @"all"];
            break;
        case LJPollFriendsVote:
            [buf appendString: @"friends"];
            break;
    }
    [buf appendString: @"\""];

    // Append viewing permission property
    [buf appendString: @" whoview=\""];
    switch(whoView) {
        case LJPollAllView:
            [buf appendString: @"all"];
            break;
        case LJPollFriendsView:
            [buf appendString: @"friends"];
            break;
        case LJPollNoneView:
            [buf appendString: @"none"];
            break;
    }
    [buf appendString: @"\""];
    
    
    [buf appendString: @">\n\n"];
	
	for (LJPollQuestion *ques in questions) {
        [buf appendString: [ques htmlRepresentation]];
        [buf appendString: @"\n\n"];
	}
	
    [buf appendString: @"</lj-poll>"];
    return [[NSString alloc] initWithString:buf];
}
@end
