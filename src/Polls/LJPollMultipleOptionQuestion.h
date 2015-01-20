//
//  LJPollRadioQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJPollQuestion.h"

typedef NS_ENUM(NSInteger, LJPollMultipleOptionType) {
    LJPollRadioType = 1,
    LJPollCheckBoxType = 2,
    LJPollDropDownType = 3
};

/*
 This subclass encapsulates the Radio, Checkbox and Drop-down question types.

 Call -setType: with one of the LJPoll*Type constants above to set the specific configuration.
 */
@interface LJPollMultipleOptionQuestion : LJPollQuestion<NSCoding>  {
    NSMutableArray *answers;
}

// Returns an autoreleased multiple-option question of the given type with
// a default question
+ (LJPollMultipleOptionQuestion *)questionOfType: (LJPollMultipleOptionType)questionType;

// Get and set the question type (with the LJPoll*Type constants)
@property LJPollMultipleOptionType type;

// Returns the number of answers to this question
@property (readonly) NSInteger numberOfAnswers;

// Adds an answer to this question
- (void)addAnswer:(NSString *)answer;

// Insert the question at the given index
- (void)insertAnswer: (NSString *)answer atIndex:(NSInteger)idx;

// Returns the answer at idx
- (NSString *)answerAtIndex: (NSInteger)idx;

// Modifies the answer at idx to reflect the given string
- (void)setAnswer:(NSString *)answer atIndex: (NSInteger)idx;

// Removes the answer at idx from the question
- (void)deleteAnswerAtIndex: (NSInteger)idx;

- (void)deleteAnswersAtIndexes:(NSIndexSet*)idx;

// Deletes all the answers
- (void)deleteAllAnswers;

// Moves the answer at oldIdx to newIdx
- (void)moveAnswerAtIndex: (NSInteger) idx toIndex: (NSInteger) newIdx;

    // Memento
@property (setter=restoreFromMemento:, copy) NSDictionary *memento;
@end
