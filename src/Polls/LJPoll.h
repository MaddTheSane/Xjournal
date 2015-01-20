//
//  LJPoll.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LJPollQuestion.h"

typedef NS_ENUM(NSInteger, LJPollVoters) {
    LJPollAllVote = 1,
    LJPollFriendsVote = 2
};

typedef NS_ENUM(NSInteger, LJPollViewers) {
    LJPollAllView = 1,
    LJPollFriendsView = 2,
    LJPollNoneView = 3
};

@interface LJPoll : NSObject {
    NSMutableArray *questions;
    NSString *name;
}

// Get and set the name of the poll
@property (copy) NSString *name;

// Get and set the voting permissions, according to the constants above (LJPoll*Vote)
@property  LJPollVoters votingPermissions;

// Get and set the viewing permissions, according to the constants above (LJPoll*View)
@property  LJPollViewers viewingPermissions;

// How many questions in the poll?
@property (readonly) NSInteger numberOfQuestions;

// Add a question to the poll
- (void)addQuestion: (LJPollQuestion *)newQ;

// Get the question at the index?
- (LJPollQuestion *)questionAtIndex: (NSInteger)idx;

// Insert the question at the given index
- (void)insertQuestion: (LJPollQuestion *)question atIndex:(NSInteger)idx;

// Move a question from idx to newIdx
- (void)moveQuestionAtIndex: (NSInteger)idx toIndex: (NSInteger)newIdx;

// Remove the question at idx
- (void)deleteQuestionAtIndex: (NSInteger)idx;

- (void)deleteQuestionsAtIndexes:(NSIndexSet*)idx;

/*
 Get the HTML representation of the entire poll.  This method
 will gather the HTML representation of every question in the
 poll.  There is no need to manually gather the HTML for every
 question in the poll.
 */
@property (readonly, copy) NSString *htmlRepresentation;
@end
