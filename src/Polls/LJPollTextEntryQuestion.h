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
@interface LJPollTextEntryQuestion : LJPollQuestion <NSCoding>

// Get and set the size property
@property NSInteger size;

// Get and set the length
@property NSInteger maxLength;

- (instancetype)init;
- (instancetype)initWithSize:(NSInteger)theSize maxLength:(NSInteger)theLength NS_DESIGNATED_INITIALIZER;

// Memento
@property (readonly, copy) NSDictionary *memento;
- (void)restoreFromMemento: (NSDictionary*)memento;

// NSCoding constructor, because Swift/ new Objc can be stupid...
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

// Returns an autoreleased text question with the given size and length
// and a default question
+ (LJPollTextEntryQuestion *)textEntryQuestionWithSize: (NSInteger)theSize maxLength: (NSInteger)theLength;

@end
