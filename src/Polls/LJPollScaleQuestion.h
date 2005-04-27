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
    NSNumber *startValue;
	int end, step;
}

// Returns an autoreleased scale question with the given startValue, end and step values
// and a default question string
+ (LJPollScaleQuestion *)scaleQuestionWithStartValue: (int)thestartValue end: (int)theEnd step:(int)theStep;

// Get and set the startValue value
- (NSNumber *)startValue;
- (void)setStartValue: (NSNumber *)newValue;

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
