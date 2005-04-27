//
//  LJPollRadioQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJPollQuestion.h"

enum {
    LJPollRadioType = 1,
    LJPollCheckBoxType = 2,
    LJPollDropDownType = 3
};

/*
 This subclass encapsulates the Radio, Checkbox and Drop-down question types.

 Call -setType: with one of the LJPoll*Type constants above to set the specific configuration.
 */
@interface LJPollMultipleOptionQuestion : LJPollQuestion {
    NSMutableArray *answers;
    int type;
}

// Returns an autoreleased multiple-option question of the given type with
// a default question
+ (LJPollMultipleOptionQuestion *)questionOfType: (int)questionType;

// Get and set the question type (with the LJPoll*Type constants)
- (int)type;
- (void)setType:(int)newType;

- (NSMutableArray *)answers;
- (void)setAnswers:(NSMutableArray *)anAnswers;

    // Memento
- (NSDictionary *) memento;
- (void) restoreFromMemento: (NSDictionary *)memento;
@end
