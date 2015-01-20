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
@interface LJPollScaleQuestion : LJPollQuestion <NSCoding>

// Returns an autoreleased scale question with the given start, end and step values
// and a default question string
+ (LJPollScaleQuestion *)scaleQuestionWithStart: (NSInteger)theStart end: (NSInteger)theEnd step:(NSInteger)theStep;

// Get and set the start value
@property NSInteger start;

// Get and set the end value
@property NSInteger end;

// Get and set the step value
@property NSInteger step;

    // Memento
@property (readonly, copy) NSDictionary *memento;
- (void)restoreFromMemento: (NSDictionary*)memento;
@end
