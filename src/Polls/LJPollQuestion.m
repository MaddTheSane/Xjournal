//
//  LJQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollQuestion.h"


@implementation LJPollQuestion

- (NSString *)question
{
    return theQuestion;
}

- (void)setQuestion: (NSString *)question
{
    [question retain];
    [theQuestion release];
    theQuestion = question;
}

- (NSString *)htmlRepresentation
{
    return @"";
}

// Memento Pattern
- (id)memento { return nil; }
- (void)restoreFromMemento: (id)memento {}
@end
