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
@interface LJPollTextEntryQuestion : LJPollQuestion {
    int size, maxLength;
}

// Returns an autoreleased text question with the given size and length
// and a default question
+ (LJPollTextEntryQuestion *)textEntryQuestionWithSize: (int)theSize maxLength: (int)theLength;

// Get and set the size property
- (int)size;
- (void)setSize:(int)newSize;

// Get and set the length
- (int)maxLength;
- (void)setMaxLength: (int)newMaxLength;

    // Memento
- (NSDictionary *) memento;
- (void) restoreFromMemento: (NSDictionary *)memento;
@end
