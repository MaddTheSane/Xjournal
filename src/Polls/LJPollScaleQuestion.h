//
//  LJPollScaleQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LJPollQuestion.h"

/*
 Question subclass representing a scale with start, end and step values
 */
@interface LJPollScaleQuestion : LJPollQuestion {
    int start, end, step;
}

// Returns an autoreleased scale question with the given start, end and step values
// and a default question string
+ (LJPollScaleQuestion *)scaleQuestionWithStart: (int)theStart end: (int)theEnd step:(int)theStep;

// Get and set the start value
- (int)start;
- (void)setStart: (int)newValue;

// Get and set the end value
- (int)end;
- (void)setEnd: (int)newValue;

// Get and set the step value
- (int)step;
- (void)setStep: (int)newValue;

    // Memento
- (NSDictionary *) memento;
- (void) restoreFromMemento: (NSDictionary *)memento;
@end
