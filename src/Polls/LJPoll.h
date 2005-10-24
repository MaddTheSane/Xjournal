//
//  LJPoll.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LJPollQuestion.h"

enum {
    LJPollAllVote = 1,
    LJPollFriendsVote = 2
};

enum {
    LJPollAllView = 1,
    LJPollFriendsView = 2,
    LJPollNoneView = 3
};

@interface LJPoll : NSObject {
    NSMutableArray *questions;
    int whoVote, whoView;
    NSString *name;
}

// Get and set the name of the poll
- (NSString *)name;
- (void)setName: (NSString *)newName;

// Get and set the voting permissions, according to the constants above (LJPoll*Vote)
- (int)votingPermissions;
- (void)setVotingPermissions: (int)newPerms;

// Get and set the viewing permissions, according to the constants above (LJPoll*View)
- (int)viewingPermissions;
- (void)setViewingPermissions: (int)newPerms;

// How many questions in the poll?
- (int)numberOfQuestions;

// Add a question to the poll
- (void)addQuestion: (LJPollQuestion *)newQ;

// Get the question at the index?
- (LJPollQuestion *)questionAtIndex: (int)idx;

// Insert the question at the given index
- (void)insertQuestion: (LJPollQuestion *)question atIndex:(int)idx;

// Move a question from idx to newIdx
- (void)moveQuestionAtIndex: (int)idx toIndex: (int)newIdx;

// Remove the question at idx
- (void)deleteQuestionAtIndex: (int)idx;

/*
 Get the HTML representation of the entire poll.  This method
 will gather the HTML representation of every question in the
 poll.  There is no need to manually gather the HTML for every
 question in the poll.
 */
- (NSString *)htmlRepresentation;
@end
