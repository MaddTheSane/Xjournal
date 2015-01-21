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

@property NSInteger start;
@property NSInteger end;
@property NSInteger step;

- (instancetype)init;
- (instancetype)initWithStart: (NSInteger)theStart end: (NSInteger)theEnd step:(NSInteger)theStep NS_DESIGNATED_INITIALIZER;

// Memento
@property (readonly, copy) NSDictionary *memento;
- (void)restoreFromMemento: (NSDictionary*)memento;

// NSCoding constructor, because Swift/ new Objc can be stupid...
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

// Returns an autoreleased scale question with the given start, end and step values
// and a default question string
+ (LJPollScaleQuestion *)scaleQuestionWithStart: (NSInteger)theStart end: (NSInteger)theEnd step:(NSInteger)theStep;
@end
