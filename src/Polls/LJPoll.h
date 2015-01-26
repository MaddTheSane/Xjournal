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
@property (copy) NSString *name;

// Get and set the voting permissions, according to the constants above (LJPoll*Vote)
- (int)votingPermissions;
- (void)setVotingPermissions: (int)newPerms;

// Get and set the viewing permissions, according to the constants above (LJPoll*View)
- (int)viewingPermissions;
- (void)setViewingPermissions: (int)newPerms;

- (NSMutableArray *)questions;
- (void)setQuestions:(NSMutableArray *)aQuestions;

	///////  questions  ///////
- (NSUInteger)countOfQuestions;
- (id)objectInQuestionsAtIndex:(NSUInteger)index;
- (void)insertObject:(id)anObject inQuestionsAtIndex:(NSUInteger)index;
- (void)removeObjectFromQuestionsAtIndex:(NSUInteger)index;
- (void)replaceObjectInQuestionsAtIndex:(NSUInteger)index withObject:(id)anObject;

/*
 Get the HTML representation of the entire poll.  This method
 will gather the HTML representation of every question in the
 poll.  There is no need to manually gather the HTML for every
 question in the poll.
 */
- (NSString *)htmlRepresentation;
@end
