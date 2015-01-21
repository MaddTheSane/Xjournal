//
//  LJQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLJPollQuestionKey @"LJPollQuestion"

@interface LJPollQuestion : NSObject <NSCoding>
// The question name
// Set the question
@property (copy) NSString *question;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

// Get the HTML representation
@property (readonly, copy) NSString *htmlRepresentation;

// Memento Pattern
@property (readonly, copy) NSDictionary *memento;
- (void)restoreFromMemento: (NSDictionary*)memento;

// NSCoding constructor, because Swift/new Objc can be stupid...
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end
