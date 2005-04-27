//
//  LJQuestion.h
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LJPollQuestion : NSObject {
    NSString *theQuestion;
}

// The question name
- (NSString *)question;

// Set the question
- (void)setQuestion: (NSString *)question;

// Get the HTML representation
- (NSString *) htmlRepresentation;

// Memento Pattern
- (id)memento;
- (void)restoreFromMemento: (id)memento;
@end
