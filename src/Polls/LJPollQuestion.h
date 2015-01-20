//
//  LJQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kLJPollQuestionKey @"LJPollQuestion"

@interface LJPollQuestion : NSObject {
    NSString *theQuestion;
}

// The question name
// Set the question
@property (copy) NSString *question;

// Get the HTML representation
@property (readonly, copy) NSString *htmlRepresentation;

// Memento Pattern
@property (setter=restoreFromMemento:, copy) id memento;
@end
