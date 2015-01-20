//
//  LJQuestion.m
//  PollTest
//
//  Created by Fraser Speirs on Fri Mar 14 2003.
//  Copyright (c) 2003 Connected Flow. All rights reserved.
//

#import "LJPollQuestion.h"


@implementation LJPollQuestion
@synthesize question = theQuestion;

- (NSString *)htmlRepresentation
{
    return @"";
}

- (instancetype)init
{
    if (self = [super init]) {
        theQuestion = @"New Question";
    }
    return self;
}

#pragma mark Memento Pattern
- (NSDictionary*)memento { return nil; }
- (void)restoreFromMemento: (NSDictionary*)memento {}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject: theQuestion forKey:kLJPollQuestionKey];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        theQuestion = [decoder decodeObjectForKey:kLJPollQuestionKey];
    }
    return self;
}

@end
