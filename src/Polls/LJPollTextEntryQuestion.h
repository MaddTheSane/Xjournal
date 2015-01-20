//
//  LJPollTextEntryQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJPollQuestion.h"

/*
 This is a subclass representing a text box question
 */
@interface LJPollTextEntryQuestion : LJPollQuestion<NSCoding>

// Returns an autoreleased text question with the given size and length
// and a default question
+ (LJPollTextEntryQuestion *)textEntryQuestionWithSize: (NSInteger)theSize maxLength: (NSInteger)theLength;

// Get and set the size property
@property NSInteger size;

// Get and set the length
@property NSInteger maxLength;

    // Memento
@property (setter=restoreFromMemento:, copy) NSDictionary *memento;
@end
