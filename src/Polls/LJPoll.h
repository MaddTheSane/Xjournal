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

- (NSMutableArray *)questions;
- (void)setQuestions:(NSMutableArray *)aQuestions;

	///////  questions  ///////
- (unsigned int)countOfQuestions;
- (id)objectInQuestionsAtIndex:(unsigned int)index;
- (void)insertObject:(id)anObject inQuestionsAtIndex:(unsigned int)index;
- (void)removeObjectFromQuestionsAtIndex:(unsigned int)index;
- (void)replaceObjectInQuestionsAtIndex:(unsigned int)index withObject:(id)anObject;

/*
 Get the HTML representation of the entire poll.  This method
 will gather the HTML representation of every question in the
 poll.  There is no need to manually gather the HTML for every
 question in the poll.
 */
- (NSString *)htmlRepresentation;
@end
