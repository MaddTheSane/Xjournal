//
//  LJPoll.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPoll.h"


@implementation LJPoll

- (id)init
{
    if([super init] == nil)
        return nil;
    
    questions = [[NSMutableArray arrayWithCapacity: 30] retain];
    name = @"NewPoll";

    return self;
}

- (void)dealloc
{
    [name release];
    [questions release];
    [super dealloc];
}

- (NSString *)name { return name; }
- (void)setName: (NSString *)newName
{
    [newName retain];
    [name release];
    name = newName;
}

- (int)votingPermissions { return whoVote; }
- (void)setVotingPermissions: (int)newPerms { whoVote = newPerms; }

- (int)viewingPermissions { return whoView; }
- (void)setViewingPermissions: (int)newPerms { whoView = newPerms; }

- (int)numberOfQuestions { return [questions count]; }

- (void)addQuestion: (LJPollQuestion *)newQ
{
    [questions addObject: newQ];
}

- (LJPollQuestion *)questionAtIndex: (int)idx
{
    return [questions objectAtIndex: idx];
}

- (void)moveQuestionAtIndex: (int)idx toIndex: (int)newIdx
{
    if(newIdx == idx) return;
    if(newIdx < 0 || newIdx >= [questions count]) return;

    id obj = [[questions objectAtIndex: idx] retain];
    [questions removeObjectAtIndex: idx];
    [questions insertObject: obj atIndex: newIdx];
    [obj release];
}

// Insert the question at the given index
- (void)insertQuestion: (LJPollQuestion *)question atIndex:(int)idx
{
    [questions insertObject: question atIndex: idx];
}
    
- (void)deleteQuestionAtIndex: (int)idx
{
    [questions removeObjectAtIndex: idx];
}

- (NSString *)htmlRepresentation
{
    NSMutableString *buf = [[NSMutableString stringWithCapacity: 100] retain];
    NSEnumerator *enu = [questions objectEnumerator];
    LJPollQuestion *ques;

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
    
    while(ques = [enu nextObject]) {
        [buf appendString: [ques htmlRepresentation]];
        [buf appendString: @"\n\n"];
    }
    [buf appendString: @"</lj-poll>"];
    return [buf autorelease];
}
@end
